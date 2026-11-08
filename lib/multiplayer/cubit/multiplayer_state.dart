part of 'multiplayer_cubit.dart';

/// Where this player is in getting to a table
enum MultiplayerConnection {
  /// Picking a name, creating or joining a room
  idle,

  /// Signing in / opening / joining a room
  connecting,

  /// Sitting in a room
  inRoom,
}

class MultiplayerState extends Equatable {
  const MultiplayerState({
    this.connection = MultiplayerConnection.idle,
    this.uid,
    this.name = '',
    this.room,
    this.now = 0,
    this.error,
    this.pendingCode,
  });

  final MultiplayerConnection connection;
  final String? uid;
  final String name;
  final MatchRoom? room;

  /// Server clock (milliseconds), ticking so countdowns move
  final int now;

  /// Something went wrong (shown on the entry screen)
  final String? error;

  /// Code from an invite link, waiting for a name
  final String? pendingCode;

  MatchStage? get stage => room?.stageAt(now);

  bool get isHost => uid != null && room?.hostUid == uid;

  /// Seconds until the next round starts (intro / scoreboard)
  int get secondsToStart => room == null ? 0 : max(0, ((room!.startsAt - now) / 1000).ceil());

  /// Seconds left in the round being played
  int get secondsLeft => room == null ? 0 : max(0, ((room!.endsAt - now) / 1000).ceil());

  /// The round the screen is about (0-based)
  int get roundShown => room?.roundShownAt(now) ?? 0;

  MultiplayerState copyWith({
    MultiplayerConnection? connection,
    String? uid,
    String? name,
    MatchRoom? room,
    bool clearRoom = false,
    int? now,
    String? error,
    bool clearError = false,
    String? pendingCode,
    bool clearPendingCode = false,
  }) {
    return MultiplayerState(
      connection: connection ?? this.connection,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      room: clearRoom ? null : (room ?? this.room),
      now: now ?? this.now,
      error: clearError ? null : (error ?? this.error),
      pendingCode: clearPendingCode ? null : (pendingCode ?? this.pendingCode),
    );
  }

  @override
  List<Object?> get props => [connection, uid, name, room, now, error, pendingCode];
}
