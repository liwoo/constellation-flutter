import 'dart:async';

import 'package:constellation_app/game/cubit/cubit.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/services/match_backend.dart';
import 'package:constellation_app/shared/constants/constants.dart';

/// The database every [FakeMatchBackend] in a test shares, with a clock the
/// test moves by hand
class FakeServer {
  int now = 1000000;
  final rooms = <String, Map<String, Object?>>{};
  final _changes = StreamController<String>.broadcast();
  var _nextCode = 0;

  void changed(String code) => _changes.add(code);

  Stream<MatchRoom?> watch(String code) async* {
    yield _read(code);
    yield* _changes.stream.where((c) => c == code).map((_) => _read(code));
  }

  MatchRoom? _read(String code) {
    final room = rooms[code];
    return room == null ? null : MatchRoom.fromJson(code, room);
  }

  String newCode() => 'ROOM${_nextCode++}';
}

/// One player's connection to the [FakeServer]
class FakeMatchBackend implements MatchBackend {
  FakeMatchBackend(this.server, this.uid);

  final FakeServer server;
  final String uid;

  Map<String, Object?> _players(String code) =>
      server.rooms[code]!.putIfAbsent('players', () => <String, Object?>{})! as Map<String, Object?>;

  @override
  Future<String> signIn() async => uid;

  @override
  int serverNow() => server.now;

  @override
  Future<String> createRoom({required String uid, required String name}) async {
    final code = server.newCode();
    server.rooms[code] = <String, Object?>{
      'hostId': uid,
      'createdAt': server.now,
      'state': <String, Object?>{'status': 'lobby'},
      'players': <String, Object?>{
        uid: <String, Object?>{'name': name, 'joinedAt': server.now, 'online': true},
      },
    };
    server.changed(code);
    return code;
  }

  @override
  Future<JoinResult> joinRoom(String code, {required String uid, required String name}) async {
    final room = server.rooms[code];
    if (room == null) return JoinResult.notFound;
    final players = _players(code);
    if (!players.containsKey(uid)) {
      if ((room['state']! as Map)['status'] != 'lobby') return JoinResult.alreadyStarted;
      if (players.length >= MultiplayerConfig.maxPlayers) return JoinResult.full;
    }
    final existing = players[uid] as Map?;
    players[uid] = <String, Object?>{
      'name': name,
      'joinedAt': existing?['joinedAt'] ?? server.now++,
      'online': true,
    };
    server.changed(code);
    return JoinResult.joined;
  }

  @override
  Stream<MatchRoom?> watchRoom(String code) => server.watch(code);

  @override
  Future<void> leaveRoom(String code, {required String uid, required bool giveUpSeat}) async {
    if (!server.rooms.containsKey(code)) return;
    final players = _players(code);
    if (giveUpSeat) {
      players.remove(uid);
      if (players.isEmpty) server.rooms.remove(code);
    } else {
      (players[uid]! as Map)['online'] = false;
    }
    server.changed(code);
  }

  @override
  Future<void> startMatch(String code, MatchSetup setup) async {
    final room = server.rooms[code]!;
    room['setup'] = setup.toJson();
    room.remove('answers');
    room.remove('ready');
    room['state'] = MatchTiming.practice();
    server.changed(code);
  }

  @override
  Future<void> markReady(String code, String uid) async {
    final ready = server.rooms[code]!.putIfAbsent('ready', () => <String, Object?>{})! as Map<String, Object?>;
    ready[uid] = true;
    server.changed(code);
  }

  @override
  Future<void> startScoring(String code) async {
    final room = server.rooms[code]!;
    room.remove('ready');
    room['state'] = MatchTiming.start(server.now);
    server.changed(code);
  }

  @override
  Future<void> abortMatch(String code) async {
    final state = server.rooms[code]!['state']! as Map<String, Object?>;
    state['status'] = MatchStatus.finished.name;
    server.changed(code);
  }

  @override
  Future<void> submitAnswer(
    String code, {
    required int round,
    required String uid,
    required MatchSubmission answer,
  }) async {
    final answers = server.rooms[code]!.putIfAbsent('answers', () => <String, Object?>{})! as Map<String, Object?>;
    final byPlayer = answers.putIfAbsent('r$round', () => <String, Object?>{})! as Map<String, Object?>;
    final mine = byPlayer.putIfAbsent(uid, () => <String, Object?>{})! as Map<String, Object?>;
    mine['c${answer.category}'] = <String, Object?>{...MatchAnswer.fields(answer), 'at': server.now};
    server.changed(code);
  }

  @override
  Future<bool> endRound(String code, {required int round, required String? by}) async {
    final room = server.rooms[code]!;
    final next = MatchTiming.endRound(
      room['state']! as Map,
      round: round,
      by: by,
      now: server.now,
      totalRounds: MultiplayerConfig.rounds,
    );
    if (next == null) return false;
    room['state'] = next;
    server.changed(code);
    return true;
  }

  @override
  Future<void> backToLobby(String code) async {
    final room = server.rooms[code]!;
    room
      ..remove('setup')
      ..remove('answers')
      ..remove('ready')
      ..['state'] = <String, Object?>{'status': 'lobby'};
    server.changed(code);
  }
}
