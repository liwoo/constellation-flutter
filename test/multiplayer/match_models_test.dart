import 'package:flutter_test/flutter_test.dart';
import 'package:constellation_app/multiplayer/models/match_models.dart';
import 'package:constellation_app/shared/constants/constants.dart';

const t0 = 1000000;

Map<String, Object?> player(String name, int joinedAt, {bool online = true}) =>
    {'name': name, 'joinedAt': joinedAt, 'online': online};

Map<String, Object?> answer(String word, int points, int at) => {'word': word, 'points': points, 'at': at};

/// A room playing [round], with three players
MatchRoom room({
  Map<String, Object?>? state,
  Map<String, Object?> answers = const {},
}) =>
    MatchRoom.fromJson('ABCDE', {
      'hostId': 'ana',
      'players': {
        'ana': player('Ana', 1),
        'ben': player('Ben', 2),
        'cy': player('Cy', 3),
      },
      'setup': {
        'seed': 7,
        'rounds': [
          for (var i = 0; i < MultiplayerConfig.rounds; i++)
            {'letter': 'C', 'categories': ['ANIMALS', 'COLORS', 'CITIES', 'CARS', 'CANDY']},
        ],
      },
      'state': state ?? MatchTiming.start(t0),
      'answers': answers,
    });

void main() {
  group('MatchTiming', () {
    final start = MatchTiming.start(t0);
    final playing = t0 + MatchTiming.introMs + 1000;

    test('the first finisher ends the round and deals the next one', () {
      final next = MatchTiming.endRound(start, round: 0, by: 'ben', now: playing, totalRounds: 8)!;
      expect(next['round'], 1);
      final r = room(state: next);
      expect(r.ends[0], RoundEnd(by: 'ben', at: playing));
      expect(r.startsAt, playing + MatchTiming.roundOverMs + MatchTiming.scoreboardMs);
      expect(r.endsAt, r.startsAt + MatchTiming.roundMs);

      // A second finisher a moment later doesn't end it again
      expect(MatchTiming.endRound(next, round: 0, by: 'cy', now: playing + 5, totalRounds: 8), isNull);
    });

    test('a round that ran out of time ends with nobody finishing, at the deadline', () {
      final late = t0 + MatchTiming.introMs + MatchTiming.roundMs + 4000;
      final next = MatchTiming.endRound(start, round: 0, by: 'ben', now: late, totalRounds: 8)!;
      final end = room(state: next).ends[0]!;
      expect(end.by, isNull);
      expect(end.at, t0 + MatchTiming.introMs + MatchTiming.roundMs);
    });

    test('rounds cannot end before they start', () {
      expect(MatchTiming.endRound(start, round: 0, by: 'ben', now: t0 + 10, totalRounds: 8), isNull);
    });

    test('the last round wraps up the match', () {
      final last = {...start, 'round': 7};
      final next = MatchTiming.endRound(last, round: 7, by: 'ana', now: playing, totalRounds: 8)!;
      expect(room(state: next).status, MatchStatus.finished);
    });

    test('everyone sees the same stage at the same server time', () {
      final r0 = room();
      expect(r0.stageAt(t0), MatchStage.intro);
      expect(r0.stageAt(playing), MatchStage.playing);
      expect(r0.stageAt(r0.endsAt), MatchStage.roundOver, reason: 'clock out, end not yet recorded');

      final r1 = room(state: MatchTiming.endRound(r0.stateJson, round: 0, by: 'ben', now: playing, totalRounds: 8));
      expect(r1.stageAt(playing + 100), MatchStage.roundOver);
      expect(r1.roundShownAt(playing + 100), 0);
      expect(r1.stageAt(playing + MatchTiming.roundOverMs + 100), MatchStage.scoreboard);
      expect(r1.roundShownAt(playing + MatchTiming.roundOverMs + 100), 0);
      expect(r1.stageAt(r1.startsAt), MatchStage.playing);
      expect(r1.roundShownAt(r1.startsAt), 1);
    });
  });

  group('MatchScoring', () {
    final end = {
      ...MatchTiming.start(t0),
      'round': 1,
      'ends': {
        'r0': {'by': 'ana', 'at': t0 + 60000},
      },
    };

    test('a word nobody else found scores double, a shared one scores once', () {
      final r = room(state: end, answers: {
        'r0': {
          'ana': {'c0': answer('CAT', 5, t0 + 100), 'c1': answer('CYAN', 9, t0 + 200)},
          'ben': {'c0': answer('cat', 5, t0 + 300), 'c1': answer('CORAL', 7, t0 + 400)},
        },
      });
      final scored = MatchScoring.scoreRound(r, 0);
      expect(scored['ana']![0]!.isUnique, isFalse);
      expect(scored['ana']![0]!.points, 5);
      expect(scored['ana']![1]!.points, 9 * MultiplayerConfig.uniqueMultiplier);
      expect(scored['ben']![1]!.points, 7 * MultiplayerConfig.uniqueMultiplier);
      expect(scored['cy'], isEmpty);
      expect(MatchScoring.roundPoints(r, 0), {'ana': 23, 'ben': 19, 'cy': 0});
    });

    test('answers landing after the round ended do not count', () {
      final r = room(state: end, answers: {
        'r0': {
          'ana': {'c0': answer('CAT', 5, t0 + 100)},
          'ben': {'c0': answer('CAT', 5, t0 + 60000 + MultiplayerConfig.lateAnswerGraceMs + 1)},
        },
      });
      // Ben's CAT came too late - Ana's is unique after all
      expect(MatchScoring.roundPoints(r, 0), {'ana': 10, 'ben': 0, 'cy': 0});
    });

    test('totals and standings across ended rounds', () {
      final r = room(state: end, answers: {
        'r0': {
          'ben': {'c0': answer('COW', 8, t0 + 100)},
          'cy': {'c0': answer('CRAB', 8, t0 + 100)},
        },
        // Round 1 is still being played - not in the totals yet
        'r1': {
          'ana': {'c0': answer('CAT', 50, t0 + 70000)},
        },
      });
      expect(MatchScoring.totals(r), {'ana': 0, 'ben': 16, 'cy': 16});
      expect(MatchScoring.standings(r).map((e) => e.key.uid), ['ben', 'cy', 'ana']);
    });
  });

  group('MatchRoom', () {
    test('host passes to the longest-seated player if the host leaves', () {
      final r = MatchRoom.fromJson('X', {
        'hostId': 'ana',
        'players': {
          'ana': player('Ana', 1, online: false),
          'cy': player('Cy', 3),
          'ben': player('Ben', 2),
        },
        'state': {'status': 'lobby'},
      });
      expect(r.hostUid, 'ben');
      expect(r.roster.map((p) => p.uid), ['ana', 'ben', 'cy']);
    });

    test('needs two players here to start', () {
      MatchRoom lobby(Map<String, Object?> players) =>
          MatchRoom.fromJson('X', {'hostId': 'ana', 'players': players, 'state': {'status': 'lobby'}});
      expect(lobby({'ana': player('Ana', 1)}).canStart, isFalse);
      expect(lobby({'ana': player('Ana', 1), 'ben': player('Ben', 2, online: false)}).canStart, isFalse);
      expect(lobby({'ana': player('Ana', 1), 'ben': player('Ben', 2)}).canStart, isTrue);
    });

    test('reads data the database turned into arrays', () {
      final r = MatchRoom.fromJson('X', {
        'hostId': 'ana',
        'players': {'ana': player('Ana', 1)},
        'state': {'status': 'playing', 'round': 0, 'startsAt': 1.0e6, 'endsAt': 2.0e6},
        'setup': {
          'seed': 3,
          'rounds': {
            '1': {'letter': 'B', 'categories': ['X', 'Y']},
            '0': {'letter': 'A', 'categories': ['P', 'Q']},
          },
        },
      });
      expect(r.setup!.rounds.map((r) => r.letter), ['A', 'B']);
      expect(r.startsAt, 1000000);
    });
  });
}

extension on MatchRoom {
  /// This room's state node, as the database holds it
  Map<String, Object?> get stateJson => {
        'status': status.name,
        'round': round,
        'startsAt': startsAt,
        'endsAt': endsAt,
        'ends': {
          for (final e in ends.entries) 'r${e.key}': {'by': e.value.by, 'at': e.value.at},
        },
      };
}
