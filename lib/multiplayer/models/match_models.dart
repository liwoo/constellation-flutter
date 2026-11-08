import 'package:equatable/equatable.dart';
import 'package:constellation_app/shared/constants/constants.dart';

// A room in the Realtime Database:
//
// rooms/{code}
//   hostId, createdAt
//   players/{uid}: {name, joinedAt, online}
//   setup: {seed, rounds: [{letter, categories: [...]}]}
//   state: {status, round, startsAt, endsAt, ends/{r0}: {by, at}}
//   answers/{r0}/{uid}/{c0}: {word, points, at}
//
// Answer and round keys carry a letter prefix so the database never turns
// them into arrays. Times are server milliseconds.

/// Where a room is at
enum MatchStatus { lobby, practice, playing, finished }

/// What every player should be looking at right now (derived from the room
/// and the server clock, so all screens move together)
enum MatchStage {
  /// Waiting for friends - the host starts when ready
  lobby,

  /// Warm-up: everyone spells the same word, then the host starts scoring
  practice,

  /// Countdown before the first round
  intro,

  /// Racing through the round's categories
  playing,

  /// Someone finished (or the clock ran out) - a beat before the scores
  roundOver,

  /// Scores between rounds, counting down to the next one
  scoreboard,

  /// Final standings
  finished,
}

class MatchPlayer extends Equatable {
  const MatchPlayer({
    required this.uid,
    required this.name,
    required this.joinedAt,
    this.online = true,
  });

  factory MatchPlayer.fromJson(String uid, Map<Object?, Object?> json) => MatchPlayer(
        uid: uid,
        name: (json['name'] as String?) ?? 'Player',
        joinedAt: _int(json['joinedAt']),
        online: json['online'] != false,
      );

  final String uid;
  final String name;
  final int joinedAt;
  final bool online;

  Map<String, Object?> toJson() => {'name': name, 'joinedAt': joinedAt, 'online': online};

  @override
  List<Object?> get props => [uid, name, joinedAt, online];
}

/// One round as dealt to everybody
class MatchRoundSetup extends Equatable {
  const MatchRoundSetup({required this.letter, required this.categories});

  factory MatchRoundSetup.fromJson(Map<Object?, Object?> json) => MatchRoundSetup(
        letter: json['letter'] as String,
        categories: _list(json['categories']).cast<String>(),
      );

  final String letter;
  final List<String> categories;

  Map<String, Object?> toJson() => {'letter': letter, 'categories': categories};

  @override
  List<Object?> get props => [letter, categories];
}

/// The whole match, dealt by the host when it starts
class MatchSetup extends Equatable {
  const MatchSetup({required this.seed, required this.rounds, this.practiceWord = ''});

  factory MatchSetup.fromJson(Map<Object?, Object?> json) => MatchSetup(
        seed: _int(json['seed']),
        practiceWord: (json['practiceWord'] as String?) ?? '',
        rounds: [
          for (final r in _list(json['rounds']))
            if (r is Map) MatchRoundSetup.fromJson(r),
        ],
      );

  final int seed;
  final List<MatchRoundSetup> rounds;

  /// The shared word everyone spells in the warm-up before scoring
  final String practiceWord;

  /// Board seed for a round (each category mixes in its own index)
  int roundSeed(int round) => (seed + 0x85EBCA6B * (round + 1)) & 0xFFFFFFFF;

  /// Board seed for the warm-up word (its own, so it looks nothing like round 1)
  int get practiceSeed => (seed ^ 0x27D4EB2F) & 0xFFFFFFFF;

  Map<String, Object?> toJson() => {
        'seed': seed,
        'practiceWord': practiceWord,
        'rounds': [for (final r in rounds) r.toJson()],
      };

  @override
  List<Object?> get props => [seed, practiceWord, rounds];
}

/// How a round ended: [by] finished first, or null if the clock ran out
class RoundEnd extends Equatable {
  const RoundEnd({required this.by, required this.at});

  factory RoundEnd.fromJson(Map<Object?, Object?> json) =>
      RoundEnd(by: json['by'] as String?, at: _int(json['at']));

  final String? by;
  final int at;

  @override
  List<Object?> get props => [by, at];
}

class MatchAnswer extends Equatable {
  const MatchAnswer({required this.word, required this.points, required this.at});

  factory MatchAnswer.fromJson(Map<Object?, Object?> json) => MatchAnswer(
        word: (json['word'] as String?) ?? '',
        points: _int(json['points']),
        at: _int(json['at']),
      );

  final String word;
  final int points;
  final int at;

  @override
  List<Object?> get props => [word, points, at];
}

class MatchRoom extends Equatable {
  const MatchRoom({
    required this.code,
    required this.hostId,
    this.players = const {},
    this.status = MatchStatus.lobby,
    this.setup,
    this.round = 0,
    this.startsAt = 0,
    this.endsAt = 0,
    this.ends = const {},
    this.answers = const {},
    this.ready = const {},
  });

  factory MatchRoom.fromJson(String code, Map<Object?, Object?> json) {
    final state = _map(json['state']);
    final setup = json['setup'];
    return MatchRoom(
      code: code,
      hostId: (json['hostId'] as String?) ?? '',
      players: {
        for (final e in _map(json['players']).entries)
          if (e.value is Map) '${e.key}': MatchPlayer.fromJson('${e.key}', e.value! as Map),
      },
      status: MatchStatus.values.asNameMap()[state['status']] ?? MatchStatus.lobby,
      setup: setup is Map ? MatchSetup.fromJson(setup) : null,
      round: _int(state['round']),
      startsAt: _int(state['startsAt']),
      endsAt: _int(state['endsAt']),
      ends: {
        for (final e in _map(state['ends']).entries)
          if (_index(e.key, 'r') case final r? when e.value is Map) r: RoundEnd.fromJson(e.value! as Map),
      },
      answers: {
        for (final round in _map(json['answers']).entries)
          if (_index(round.key, 'r') case final r?)
            r: {
              for (final player in _map(round.value).entries)
                '${player.key}': {
                  for (final answer in _map(player.value).entries)
                    if (_index(answer.key, 'c') case final c? when answer.value is Map)
                      c: MatchAnswer.fromJson(answer.value! as Map),
                },
            },
      },
      ready: {
        for (final e in _map(json['ready']).entries)
          if (e.value == true) '${e.key}': true,
      },
    );
  }

  final String code;
  final String hostId;
  final Map<String, MatchPlayer> players;
  final MatchStatus status;
  final MatchSetup? setup;

  /// Current (or next, during the scoreboard) round, 0-based
  final int round;

  /// When [round] starts and its clock runs out
  final int startsAt;
  final int endsAt;

  /// Rounds already over
  final Map<int, RoundEnd> ends;

  /// round -> player -> category index -> answer
  final Map<int, Map<String, Map<int, MatchAnswer>>> answers;

  /// Who has spelled the warm-up word (uid -> true)
  final Map<String, bool> ready;

  int get totalRounds => setup?.rounds.length ?? MultiplayerConfig.rounds;

  /// Players in the order they joined
  List<MatchPlayer> get roster => players.values.toList()
    ..sort((a, b) {
      final byJoin = a.joinedAt.compareTo(b.joinedAt);
      return byJoin != 0 ? byJoin : a.uid.compareTo(b.uid);
    });

  List<MatchPlayer> get onlinePlayers => roster.where((p) => p.online).toList();

  /// Who runs the lobby: the creator, or if they've gone, whoever's been
  /// here longest
  String? get hostUid {
    if (players[hostId]?.online ?? false) return hostId;
    final online = onlinePlayers;
    return online.isEmpty ? null : online.first.uid;
  }

  bool get isFull => players.length >= MultiplayerConfig.maxPlayers;

  bool get canStart => status == MatchStatus.lobby && onlinePlayers.length >= MultiplayerConfig.minPlayers;

  /// Everyone here has spelled the warm-up word
  bool isReady(String uid) => ready[uid] == true;

  /// How many of the players here have finished the warm-up
  int get readyCount => onlinePlayers.where((p) => isReady(p.uid)).length;

  /// The host can kick off scoring: in the warm-up, enough players, all ready
  bool get canStartScoring =>
      status == MatchStatus.practice &&
      onlinePlayers.length >= MultiplayerConfig.minPlayers &&
      onlinePlayers.every((p) => isReady(p.uid));

  MatchStage stageAt(int now) {
    switch (status) {
      case MatchStatus.lobby:
        return MatchStage.lobby;
      case MatchStatus.practice:
        return MatchStage.practice;
      case MatchStatus.finished:
        final last = ends[totalRounds - 1];
        if (last != null && now < last.at + MatchTiming.roundOverMs) return MatchStage.roundOver;
        return MatchStage.finished;
      case MatchStatus.playing:
        if (now < startsAt) {
          if (round == 0) return MatchStage.intro;
          final previous = ends[round - 1];
          if (previous != null && now < previous.at + MatchTiming.roundOverMs) {
            return MatchStage.roundOver;
          }
          return MatchStage.scoreboard;
        }
        return now < endsAt ? MatchStage.playing : MatchStage.roundOver;
    }
  }

  /// The round the stage is about (the one just played, while its result
  /// is up)
  int roundShownAt(int now) {
    if (status == MatchStatus.finished) return totalRounds - 1;
    if (status == MatchStatus.playing && now < startsAt && round > 0) return round - 1;
    return round;
  }

  /// Categories answered so far this round, per player
  Map<String, int> progress(int round) => {
        for (final p in players.keys) p: answers[round]?[p]?.length ?? 0,
      };

  @override
  List<Object?> get props =>
      [code, hostId, players, status, setup, round, startsAt, endsAt, ends, answers, ready];
}

/// Room clock rules shared by every client
class MatchTiming {
  const MatchTiming._();

  /// "Round over" banner before the scoreboard (milliseconds)
  static const int roundOverMs = 2500;

  static const int roundMs = MultiplayerConfig.roundSeconds * 1000;
  static const int scoreboardMs = MultiplayerConfig.scoreboardSeconds * 1000;
  static const int introMs = MultiplayerConfig.introSeconds * 1000;

  /// The room state for the warm-up: no clock, players spell the shared word
  /// and the host starts scoring once everyone's ready
  static Map<String, Object?> practice() => {'status': MatchStatus.practice.name};

  /// The room state that starts a match at [now]
  static Map<String, Object?> start(int now) {
    final startsAt = now + introMs;
    return {
      'status': MatchStatus.playing.name,
      'round': 0,
      'startsAt': startsAt,
      'endsAt': startsAt + roundMs,
      'ends': null,
    };
  }

  /// The room state once [round] ends at [now] - finished first by [by],
  /// or by the clock - or null if it already ended. Ending a round deals
  /// the next one after the round-over beat and the scoreboard, or wraps up
  /// the match.
  static Map<String, Object?>? endRound(
    Map<Object?, Object?>? state, {
    required int round,
    required String? by,
    required int now,
    required int totalRounds,
  }) {
    if (state == null) return null;
    if (state['status'] != MatchStatus.playing.name) return null;
    if (_int(state['round']) != round) return null;
    if (now < _int(state['startsAt'])) return null; // Not started yet

    // The clock can't be beaten by a late finish
    final endsAt = _int(state['endsAt']);
    final ended = {'by': now <= endsAt ? by : null, 'at': now <= endsAt ? now : endsAt};
    final ends = {..._map(state['ends']).map((k, v) => MapEntry('$k', v)), 'r$round': ended};

    if (round + 1 >= totalRounds) {
      return {...state.map((k, v) => MapEntry('$k', v)), 'status': MatchStatus.finished.name, 'ends': ends};
    }
    final startsAt = (ended['at']! as int) + roundOverMs + scoreboardMs;
    return {
      'status': MatchStatus.playing.name,
      'round': round + 1,
      'startsAt': startsAt,
      'endsAt': startsAt + roundMs,
      'ends': ends,
    };
  }
}

/// A player's answer for one category, once the round is scored
class ScoredAnswer extends Equatable {
  const ScoredAnswer({required this.word, required this.basePoints, required this.isUnique});

  final String word;
  final int basePoints;

  /// Nobody else found this word for this category
  final bool isUnique;

  int get points => isUnique ? basePoints * MultiplayerConfig.uniqueMultiplier : basePoints;

  @override
  List<Object?> get props => [word, basePoints, isUnique];
}

/// Scoring: a correct word scores its points; a word nobody else found for
/// that category scores [MultiplayerConfig.uniqueMultiplier] times as much.
class MatchScoring {
  const MatchScoring._();

  static String _normalize(String word) => word.toUpperCase().replaceAll(RegExp('[^A-Z]'), '');

  /// Answers that count for [round]: those in before it ended
  static Map<String, Map<int, MatchAnswer>> _onTime(MatchRoom room, int round) {
    final end = room.ends[round];
    final all = room.answers[round] ?? const {};
    if (end == null) return all;
    final cutoff = end.at + MultiplayerConfig.lateAnswerGraceMs;
    return {
      for (final e in all.entries)
        e.key: {
          for (final a in e.value.entries)
            if (a.value.at <= cutoff) a.key: a.value,
        },
    };
  }

  /// Every player's scored answers for [round], by category index
  static Map<String, Map<int, ScoredAnswer>> scoreRound(MatchRoom room, int round) {
    final answers = _onTime(room, round);
    final counts = <int, Map<String, int>>{};
    for (final byCategory in answers.values) {
      for (final e in byCategory.entries) {
        final word = _normalize(e.value.word);
        final forCategory = counts.putIfAbsent(e.key, () => {});
        forCategory[word] = (forCategory[word] ?? 0) + 1;
      }
    }
    return {
      for (final uid in room.players.keys)
        uid: {
          for (final e in (answers[uid] ?? const <int, MatchAnswer>{}).entries)
            e.key: ScoredAnswer(
              word: e.value.word,
              basePoints: e.value.points,
              isUnique: counts[e.key]![_normalize(e.value.word)] == 1,
            ),
        },
    };
  }

  /// Points each player scored in [round]
  static Map<String, int> roundPoints(MatchRoom room, int round) => {
        for (final e in scoreRound(room, round).entries)
          e.key: e.value.values.fold(0, (sum, a) => sum + a.points),
      };

  /// Match totals over the rounds that have ended
  static Map<String, int> totals(MatchRoom room) {
    final totals = {for (final uid in room.players.keys) uid: 0};
    for (final round in room.ends.keys) {
      for (final e in roundPoints(room, round).entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }
    return totals;
  }

  /// Players ranked by total, best first (ties keep join order)
  static List<MapEntry<MatchPlayer, int>> standings(MatchRoom room) {
    final totals = MatchScoring.totals(room);
    final ranked = [for (final p in room.roster) MapEntry(p, totals[p.uid] ?? 0)];
    // Stable: List.sort isn't, so break ties on join order
    final order = {for (final (i, p) in room.roster.indexed) p.uid: i};
    ranked.sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      return byScore != 0 ? byScore : order[a.key.uid]!.compareTo(order[b.key.uid]!);
    });
    return ranked;
  }
}

// Database values arrive loosely typed (and numbers may be doubles on web)
int _int(Object? v) => v is num ? v.toInt() : 0;

Map<Object?, Object?> _map(Object? v) => switch (v) {
      final Map<Object?, Object?> m => m,
      final List<Object?> l => {for (final (i, e) in l.indexed) if (e != null) '$i': e},
      _ => const {},
    };

List<Object?> _list(Object? v) => switch (v) {
      final List<Object?> l => l.where((e) => e != null).toList(),
      final Map<Object?, Object?> m => (m.entries.toList()
            ..sort((a, b) => (int.tryParse('${a.key}') ?? 0).compareTo(int.tryParse('${b.key}') ?? 0)))
          .map((e) => e.value)
          .toList(),
      _ => const [],
    };

/// "r3" -> 3
int? _index(Object? key, String prefix) {
  final k = '$key';
  return k.startsWith(prefix) ? int.tryParse(k.substring(prefix.length)) : null;
}
