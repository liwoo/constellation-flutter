import 'package:constellation_app/multiplayer/models/match_models.dart';

/// Why joining a room didn't work
enum JoinResult { joined, notFound, full, alreadyStarted }

/// Realtime room storage for multiplayer matches. Firebase in the app;
/// in-memory in tests.
abstract class MatchBackend {
  /// Sign in (anonymously) and return this player's id
  Future<String> signIn();

  /// Best estimate of the server clock (milliseconds since epoch)
  int serverNow();

  /// Open a new lobby hosted by [uid]; returns its room code
  Future<String> createRoom({required String uid, required String name});

  /// Take a seat in a lobby (or back in a match already holding one)
  Future<JoinResult> joinRoom(String code, {required String uid, required String name});

  /// The room as it changes; null once it's gone
  Stream<MatchRoom?> watchRoom(String code);

  /// Get up from the table. From the lobby the seat is given up; mid-match
  /// the player just shows as away, scores intact.
  Future<void> leaveRoom(String code, {required String uid, required bool giveUpSeat});

  /// Deal the match and start the clock
  Future<void> startMatch(String code, MatchSetup setup);

  /// Record an answer (stamped with server time)
  Future<void> submitAnswer(
    String code, {
    required int round,
    required int category,
    required String uid,
    required String word,
    required int points,
  });

  /// End [round] - [by] finished it, or null when the clock ran out.
  /// Safe to race: only the first call for a round lands. Returns whether
  /// this call ended it.
  Future<bool> endRound(String code, {required int round, required String? by});

  /// Everyone back to the lobby for another match
  Future<void> backToLobby(String code);
}
