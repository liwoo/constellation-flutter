import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/game/services/category_dictionary.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/services/firebase_match_backend.dart';
import 'package:constellation_app/multiplayer/services/match_backend.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';

part 'multiplayer_state.dart';

/// Runs a seat at a multiplayer table: the lobby, then the match round by
/// round. The room in the database is the source of truth - every client
/// derives what to show from it and the server clock, so screens move
/// together. Gameplay itself is the single-player engine ([game]) playing
/// the round everyone was dealt.
class MultiplayerCubit extends Cubit<MultiplayerState> {
  MultiplayerCubit({MatchBackend Function()? backend})
      : _makeBackend = backend ?? FirebaseMatchBackend.new,
        super(const MultiplayerState());

  final MatchBackend Function() _makeBackend;
  MatchBackend? _backendInstance;

  /// The board this player races on
  late final GameCubit game = GameCubit(
    onMatchAnswer: _onAnswer,
    onMatchFinished: _onFinished,
    onPracticeComplete: _onPracticeComplete,
  );

  StreamSubscription<MatchRoom?>? _roomSub;
  Timer? _clock;
  final _random = Random();

  // Round the board is playing (null between rounds)
  int? _playingRound;
  // Whether the warm-up practice board is up
  bool _practiceStarted = false;
  // Rounds this client already asked to end on the clock
  final _timeoutsSent = <int>{};
  // Answer writes, in order - finishing waits for them to land
  Future<void> _writes = Future.value();

  /// Load the saved name; [joinCode] comes from an invite link
  Future<void> init({String? joinCode}) async {
    final saved = await StorageService.instance.loadPlayerName();
    final code = _cleanCode(joinCode ?? '');
    emit(state.copyWith(name: saved ?? '', pendingCode: code.isEmpty ? null : code));
    // Invited, and we know who you are - straight to the lobby
    if (code.isNotEmpty && (saved ?? '').trim().isNotEmpty) {
      await joinRoom(code, saved!);
    }
  }

  // ============================================
  // ENTRY
  // ============================================

  Future<void> createRoom(String name) => _enter(name, (backend, uid, name) async {
        final code = await backend.createRoom(uid: uid, name: name);
        return (code, null);
      });

  Future<void> joinRoom(String code, String name) => _enter(name, (backend, uid, name) async {
        final clean = _cleanCode(code);
        final result = await backend.joinRoom(clean, uid: uid, name: name);
        return switch (result) {
          JoinResult.joined => (clean, null),
          JoinResult.notFound => (null, 'No game with code $clean'),
          JoinResult.full => (null, 'That game is full (${MultiplayerConfig.maxPlayers} players max)'),
          JoinResult.alreadyStarted => (null, 'That game has already started'),
        };
      });

  Future<void> _enter(
    String rawName,
    Future<(String?, String?)> Function(MatchBackend backend, String uid, String name) open,
  ) async {
    if (state.connection != MultiplayerConnection.idle) return;
    final name = _cleanName(rawName);
    if (name.isEmpty) {
      emit(state.copyWith(error: 'Pick a name first'));
      return;
    }
    emit(state.copyWith(connection: MultiplayerConnection.connecting, name: name, clearError: true));
    unawaited(StorageService.instance.savePlayerName(name));

    try {
      final backend = _backend();
      final uid = state.uid ?? await backend.signIn();
      final (code, error) = await open(backend, uid, name);
      if (isClosed) return;
      if (code == null) {
        emit(state.copyWith(connection: MultiplayerConnection.idle, uid: uid, error: error));
        return;
      }
      emit(state.copyWith(
        connection: MultiplayerConnection.inRoom,
        uid: uid,
        now: backend.serverNow(),
        clearPendingCode: true,
      ));
      _watch(code);
    } catch (e) {
      debugPrint('Multiplayer: could not connect - $e');
      if (isClosed) return;
      emit(state.copyWith(
        connection: MultiplayerConnection.idle,
        error: Firebase.apps.isEmpty
            ? 'Multiplayer needs Firebase - it isn\'t set up on this build'
            : 'Couldn\'t reach the game server. Check your connection and try again.',
      ));
    }
  }

  MatchBackend _backend() => _backendInstance ??= _makeBackend();

  void _watch(String code) {
    _roomSub?.cancel();
    _roomSub = _backend().watchRoom(code).listen(_onRoom, onError: (Object e) {
      debugPrint('Multiplayer: room stream error - $e');
    });
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _onRoom(MatchRoom? room) {
    if (isClosed) return;
    if (room == null) {
      _closeTable();
      emit(state.copyWith(
        connection: MultiplayerConnection.idle,
        clearRoom: true,
        error: 'That game has closed',
      ));
      return;
    }
    // Back in the lobby (play again) - fresh match bookkeeping
    if (room.status == MatchStatus.lobby && state.room?.status != MatchStatus.lobby) {
      _timeoutsSent.clear();
    }
    emit(state.copyWith(room: room, now: _backend().serverNow()));
    _sync();
  }

  void _tick() {
    if (isClosed || state.room == null) return;
    emit(state.copyWith(now: _backend().serverNow()));
    _sync();
  }

  /// Bring the board in line with the room: start the round when its clock
  /// starts, freeze it when the round ends, and end a round whose clock has
  /// run out (any player can - only the first lands)
  void _sync() {
    final room = state.room;
    if (room == null) return;
    final now = state.now;
    final stage = room.stageAt(now);

    // Warm-up board: up while this player hasn't spelled the word yet
    final inPractice = stage == MatchStage.practice && !room.isReady(state.uid ?? '');
    if (inPractice && !_practiceStarted) {
      _startPractice(room);
    } else if (!inPractice && _practiceStarted) {
      _practiceStarted = false;
      game.endPractice();
    }

    if (stage == MatchStage.playing && _playingRound != room.round) {
      _startRound(room);
    } else if (stage != MatchStage.playing && _playingRound != null) {
      _playingRound = null;
      game.endMatchRound();
    }

    if (room.status == MatchStatus.playing &&
        now >= room.endsAt &&
        _timeoutsSent.add(room.round)) {
      unawaited(_backend()
          .endRound(room.code, round: room.round, by: null)
          .catchError((Object e) {
        _timeoutsSent.remove(room.round); // Try again next tick
        return false;
      }));
    }
  }

  void _startPractice(MatchRoom room) {
    final setup = room.setup;
    if (setup == null || setup.practiceWord.isEmpty) return;
    _practiceStarted = true;
    game.startPracticeWord(word: setup.practiceWord, seed: setup.practiceSeed);
  }

  /// The player spelled the warm-up word: tell everyone they're ready
  void _onPracticeComplete() {
    final room = state.room;
    final uid = state.uid;
    if (room == null || uid == null) return;
    _writes = _writes
        .then((_) => _backend().markReady(room.code, uid))
        .catchError((Object e) => debugPrint('Multiplayer: ready not saved - $e'));
  }

  void _startRound(MatchRoom room) {
    final setup = room.setup;
    if (setup == null || room.round >= setup.rounds.length) return;
    final dealt = setup.rounds[room.round];
    _playingRound = room.round;
    // Server time -> this device's clock
    final skew = state.now - DateTime.now().millisecondsSinceEpoch;
    game.startMatchRound(MatchRound(
      number: room.round + 1,
      totalRounds: setup.rounds.length,
      letter: dealt.letter,
      categories: dealt.categories,
      seed: setup.roundSeed(room.round),
      endsAt: DateTime.fromMillisecondsSinceEpoch(room.endsAt - skew),
    ));
  }

  void _onAnswer(MatchSubmission answer) {
    final room = state.room;
    final round = _playingRound;
    final uid = state.uid;
    if (room == null || round == null || uid == null || answer.category < 0) return;
    _writes = _writes
        .then((_) => _backend().submitAnswer(room.code, round: round, uid: uid, answer: answer))
        .catchError((Object e) => debugPrint('Multiplayer: answer not saved - $e'));
  }

  /// Every category answered: this player ends the round for everyone, once
  /// their last answer is safely in
  void _onFinished() {
    final room = state.room;
    final round = _playingRound;
    final uid = state.uid;
    if (room == null || round == null || uid == null) return;
    _writes = _writes
        .then((_) => _backend().endRound(room.code, round: round, by: uid))
        .then((_) {}, onError: (Object e) => debugPrint('Multiplayer: could not end round - $e'));
  }

  // ============================================
  // HOST
  // ============================================

  /// Deal the match and open the warm-up (host only, 2+ players here)
  Future<void> startMatch() async {
    final room = state.room;
    if (room == null || !state.isHost || !room.canStart) return;
    AudioService.instance.play(GameSound.jackpotReveal);
    await _backend().startMatch(room.code, dealMatch(_random));
  }

  /// Everyone's spelled the warm-up word: start the scored rounds (host only)
  Future<void> startScoring() async {
    final room = state.room;
    if (room == null || !state.isHost || !room.canStartScoring) return;
    AudioService.instance.play(GameSound.jackpotReveal);
    await _backend().startScoring(room.code);
  }

  /// End the match now and jump everyone to the final scores (host only)
  Future<void> abortMatch() async {
    final room = state.room;
    if (room == null || !state.isHost) return;
    if (room.status != MatchStatus.playing && room.status != MatchStatus.practice) return;
    await _backend().abortMatch(room.code);
  }

  /// Everyone back to the lobby for another go (host only)
  Future<void> playAgain() async {
    final room = state.room;
    if (room == null || !state.isHost || room.status != MatchStatus.finished) return;
    await _backend().backToLobby(room.code);
  }

  /// Letters ramp from easy to hard across the match (never repeating), each
  /// with five categories that have answers for it
  @visibleForTesting
  static MatchSetup dealMatch(Random random) {
    final used = <String>{};
    final rounds = <MatchRoundSetup>[];
    for (var n = 1; n <= MultiplayerConfig.rounds; n++) {
      final difficultyRound = MultiplayerConfig.difficultyRound(n);
      final maxDifficulty = DifficultyConfig.getMaxDifficulty(difficultyRound);
      final letters = [
        for (var i = 0; i < 26; i++) String.fromCharCode(65 + i),
      ].where((l) => l != 'X' && !used.contains(l)).toList()
        ..shuffle(random);
      // Easiest allowed first, then anything left as a fallback
      letters.sort((a, b) {
        final da = DifficultyConfig.letterDifficulty[a] ?? 3;
        final db = DifficultyConfig.letterDifficulty[b] ?? 3;
        return (da > maxDifficulty ? 1 : 0).compareTo(db > maxDifficulty ? 1 : 0);
      });

      for (final letter in letters) {
        final categories = _categoriesFor(letter, difficultyRound, random);
        if (categories.length < GameState.categoriesPerLetter) continue;
        used.add(letter);
        rounds.add(MatchRoundSetup(letter: letter, categories: categories));
        break;
      }
    }
    final practiceWord =
        MultiplayerConfig.practiceWords[random.nextInt(MultiplayerConfig.practiceWords.length)];
    return MatchSetup(seed: random.nextInt(1 << 31), rounds: rounds, practiceWord: practiceWord);
  }

  static List<String> _categoriesFor(String letter, int difficultyRound, Random random) {
    final weighted = CategoryService.instance
        .getNRandomCategoriesWeighted(letter, difficultyRound, GameState.categoriesPerLetter)
        .map((c) => c.name.toUpperCase())
        .toList();
    if (weighted.length >= GameState.categoriesPerLetter) return weighted;

    final dictionary = CategoryDictionary.instance;
    final valid = CategoryDictionary.categories
        .where((c) => dictionary.categoryHasWordsForLetter(c, letter))
        .toList()
      ..shuffle(random);
    return valid.take(GameState.categoriesPerLetter).toList();
  }

  // ============================================
  // LEAVING
  // ============================================

  /// Get up from the table
  Future<void> leave() async {
    final room = state.room;
    final uid = state.uid;
    _closeTable();
    emit(state.copyWith(connection: MultiplayerConnection.idle, clearRoom: true, clearError: true));
    if (room == null || uid == null) return;
    try {
      await _backend().leaveRoom(
        room.code,
        uid: uid,
        // Mid-match the seat (and score) stays, in case they come back
        giveUpSeat: room.status == MatchStatus.lobby,
      );
    } catch (e) {
      debugPrint('Multiplayer: leave failed - $e');
    }
  }

  void _closeTable() {
    _roomSub?.cancel();
    _roomSub = null;
    _clock?.cancel();
    _clock = null;
    _playingRound = null;
    _practiceStarted = false;
    _timeoutsSent.clear();
    game.endPractice();
    game.endMatchRound();
  }

  void clearError() => emit(state.copyWith(clearError: true));

  static String _cleanName(String name) {
    final trimmed = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    return trimmed.length > MultiplayerConfig.maxNameLength
        ? trimmed.substring(0, MultiplayerConfig.maxNameLength)
        : trimmed;
  }

  static String _cleanCode(String code) => code.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  @override
  Future<void> close() async {
    if (state.room != null) unawaited(leave());
    _closeTable();
    await game.close();
    return super.close();
  }
}
