import 'dart:async';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/multiplayer/services/match_backend.dart';
import 'package:constellation_app/shared/constants/constants.dart';

/// Rooms in the Firebase Realtime Database, players signed in anonymously
class FirebaseMatchBackend implements MatchBackend {
  FirebaseMatchBackend({FirebaseDatabase? database, FirebaseAuth? auth})
      : _db = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final _random = Random.secure();

  int _serverOffset = 0;
  StreamSubscription<DatabaseEvent>? _offsetSub;
  StreamSubscription<DatabaseEvent>? _presenceSub;

  DatabaseReference _room(String code) => _db.ref('rooms/$code');

  @override
  Future<String> signIn() async {
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user;
    if (user == null) throw StateError('Could not sign in');
    _offsetSub ??= _db.ref('.info/serverTimeOffset').onValue.listen((event) {
      final offset = event.snapshot.value;
      if (offset is num) _serverOffset = offset.toInt();
    });
    return user.uid;
  }

  @override
  int serverNow() => DateTime.now().millisecondsSinceEpoch + _serverOffset;

  @override
  Future<String> createRoom({required String uid, required String name}) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      final code = _newCode();
      final now = serverNow();
      final result = await _room(code).runTransaction((current) {
        if (current != null) return Transaction.abort(); // Code taken
        return Transaction.success({
          'hostId': uid,
          'createdAt': now,
          'state': {'status': MatchStatus.lobby.name},
          'players': {
            uid: MatchPlayer(uid: uid, name: name, joinedAt: now).toJson(),
          },
        });
      }, applyLocally: false);
      if (result.committed) {
        _watchPresence(code, uid);
        return code;
      }
    }
    throw StateError('Could not open a room');
  }

  @override
  Future<JoinResult> joinRoom(String code, {required String uid, required String name}) async {
    final snapshot = await _room(code).get();
    final value = snapshot.value;
    if (value is! Map) return JoinResult.notFound;
    final room = MatchRoom.fromJson(code, value);
    final me = _room(code).child('players/$uid');

    if (room.players.containsKey(uid)) {
      // Back in a seat already held (rejoining, even mid-match)
      await me.update({'name': name, 'online': true});
    } else {
      if (room.status != MatchStatus.lobby) return JoinResult.alreadyStarted;
      if (room.isFull) return JoinResult.full;
      await me.set({'name': name, 'joinedAt': ServerValue.timestamp, 'online': true});

      // Two people can grab the last seat at once: whoever sat down later
      // (by server time) gets up again
      final players = (await _room(code).child('players').get()).value;
      final seated = MatchRoom.fromJson(code, {'players': players}).roster;
      if (seated.indexWhere((p) => p.uid == uid) >= MultiplayerConfig.maxPlayers) {
        await me.remove();
        return JoinResult.full;
      }
    }

    _watchPresence(code, uid);
    return JoinResult.joined;
  }

  /// Online while connected - the server flips it off if the app drops
  void _watchPresence(String code, String uid) {
    _presenceSub?.cancel();
    final online = _room(code).child('players/$uid/online');
    _presenceSub = _db.ref('.info/connected').onValue.listen((event) async {
      if (event.snapshot.value != true) return;
      await online.onDisconnect().set(false);
      await online.set(true);
    });
  }

  @override
  Stream<MatchRoom?> watchRoom(String code) => _room(code).onValue.map((event) {
        final value = event.snapshot.value;
        return value is Map ? MatchRoom.fromJson(code, value) : null;
      });

  @override
  Future<void> leaveRoom(String code, {required String uid, required bool giveUpSeat}) async {
    await _presenceSub?.cancel();
    _presenceSub = null;
    final player = _room(code).child('players/$uid');
    await player.child('online').onDisconnect().cancel();
    if (!giveUpSeat) {
      await player.child('online').set(false);
      return;
    }
    await player.remove();
    // Last one out closes the room
    // (A null here may just be an empty local cache: writing null then is
    // harmless - the server reruns the handler with the real room.)
    await _room(code).runTransaction((current) {
      if (current == null || (current is Map && current['players'] == null)) {
        return Transaction.success(null);
      }
      return Transaction.abort();
    }, applyLocally: false);
  }

  @override
  Future<void> startMatch(String code, MatchSetup setup) => _room(code).update({
        'setup': setup.toJson(),
        'answers': null,
        'state': MatchTiming.start(serverNow()),
      });

  @override
  Future<void> submitAnswer(
    String code, {
    required int round,
    required int category,
    required String uid,
    required String word,
    required int points,
  }) =>
      _room(code).child('answers/r$round/$uid/c$category').set({
        'word': word,
        'points': points,
        'at': ServerValue.timestamp,
      });

  @override
  Future<bool> endRound(String code, {required int round, required String? by}) async {
    final result = await _room(code).child('state').runTransaction((current) {
      // Not cached locally yet - a null write makes the server rerun this
      // with the real state
      if (current == null) return Transaction.success(null);
      final next = MatchTiming.endRound(
        current is Map ? current : null,
        round: round,
        by: by,
        now: serverNow(),
        totalRounds: MultiplayerConfig.rounds,
      );
      return next == null ? Transaction.abort() : Transaction.success(next);
    }, applyLocally: false);
    return result.committed && result.snapshot.value != null;
  }

  @override
  Future<void> backToLobby(String code) => _room(code).update({
        'setup': null,
        'answers': null,
        'state': {'status': MatchStatus.lobby.name},
      });

  String _newCode() => String.fromCharCodes(List.generate(
        MultiplayerConfig.codeLength,
        (_) => MultiplayerConfig.codeAlphabet.codeUnitAt(
          _random.nextInt(MultiplayerConfig.codeAlphabet.length),
        ),
      ));
}
