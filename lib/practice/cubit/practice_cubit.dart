import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/shared/constants/constants.dart';
import 'package:constellation_app/shared/services/services.dart';

part 'practice_state.dart';

/// Practice: a few tiny lessons, one mechanic each. No clock, no
/// categories, no score - just the controls, behaving exactly like the
/// real game (same hit radii, dwell time, sounds and haptics).
class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit() : super(const PracticeState()) {
    startLesson(0);
  }

  static const Duration _dwellTime = Duration(milliseconds: HitDetectionConfig.dwellTimeMs);
  static const double _innerHitRadius = HitDetectionConfig.innerHitRadius;
  static const double _outerHitRadius = HitDetectionConfig.outerHitRadius;

  /// Pause on the "nice!" celebration before the next lesson
  static const Duration lessonCelebration = Duration(milliseconds: 1400);

  int? _pendingLetterId;
  DateTime? _pendingLetterEnteredAt;
  Offset? _lastDragPosition;
  Timer? _dwellTimer;
  Timer? _guideTimer;
  Timer? _advanceTimer;

  /// Load lesson [index] fresh
  void startLesson(int index) {
    _cancelTimers();
    final lesson = practiceLessons[index];
    var id = 0;
    final letters = [
      for (final entry in lesson.stars.entries)
        LetterNode(
          id: id++,
          letter: entry.key,
          points: LetterPoints.values[entry.key] ?? 1,
          position: entry.value,
        ),
    ];
    emit(PracticeState(lessonIndex: index, letters: letters));
    showMe();
  }

  /// Start over from the first lesson
  void restart() => startLesson(0);

  // ============================================
  // SHOW ME - the word's path lights up star by star
  // ============================================

  void showMe() {
    _guideTimer?.cancel();
    final ids = [
      for (final char in state.targetWord.replaceAll(' ', '').split(''))
        state.letters.firstWhere((l) => l.letter == char).id,
    ];
    emit(state.copyWith(guideIds: ids, guideIndex: 0));

    var step = 0;
    _guideTimer = Timer.periodic(
      const Duration(milliseconds: AnimationConfig.hintLetterRevealDelay),
      (timer) {
        if (isClosed) return timer.cancel();
        step++;
        if (step <= ids.length) {
          AudioService.instance.playSnap(step, volume: 0.35);
          emit(state.copyWith(guideIndex: step));
        } else if (step > ids.length + 2) {
          timer.cancel();
          emit(state.copyWith(guideIds: const [], guideIndex: 0));
        }
      },
    );
  }

  void _stopGuide() {
    if (state.guideIds.isEmpty) return;
    _guideTimer?.cancel();
    emit(state.copyWith(guideIds: const [], guideIndex: 0));
  }

  // ============================================
  // DRAGGING - mirrors GameCubit
  // ============================================

  void startDrag(Offset position) {
    if (state.phase != PracticePhase.playing) return;
    _stopGuide();
    _resetPending();
    _lastDragPosition = position;

    emit(state.copyWith(isDragging: true, currentDragPosition: position));

    // Touching a star selects it straight away (no dwell to start)
    final hit = _findStarAt(position, _innerHitRadius);
    if (hit != null && hit.id != _lastSelectedId) _confirm(hit.id, position);
  }

  void updateDrag(Offset position) {
    if (!state.isDragging) return;
    _lastDragPosition = position;
    final hit = _findStarAt(position, _outerHitRadius);

    if (hit != null && hit.id != _lastSelectedId) {
      if (_pendingLetterId == hit.id) {
        if (DateTime.now().difference(_pendingLetterEnteredAt!) >= _dwellTime) {
          _confirm(hit.id, position);
        } else {
          emit(state.copyWith(currentDragPosition: position));
        }
      } else {
        // Arrived on a new star - the ring starts filling
        final now = DateTime.now();
        _pendingLetterId = hit.id;
        _pendingLetterEnteredAt = now;
        _scheduleDwellConfirm(hit.id);
        emit(state.copyWith(
          currentDragPosition: position,
          approachingLetterIds: [hit.id],
          pendingLetterId: hit.id,
          letterDwellStartTime: now,
        ));
      }
      return;
    }

    _resetPending();
    emit(state.copyWith(
      currentDragPosition: position,
      approachingLetterIds: const [],
      clearPending: true,
    ));
  }

  void endDrag() {
    // Lifted while the right star's ring was still filling - nudge them
    final pending = _pendingLetterId;
    final liftedEarly = pending != null &&
        state.letters.firstWhere((l) => l.id == pending).letter == state.nextLetter;
    _resetPending();
    emit(state.copyWith(
      isDragging: false,
      clearDragPosition: true,
      approachingLetterIds: const [],
      clearPending: true,
      releasedEarly: liftedEarly ? true : null,
    ));
  }

  /// Holding perfectly still sends no move events, so the click is also
  /// delivered by a timer
  void _scheduleDwellConfirm(int id) {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(_dwellTime, () {
      if (isClosed || !state.isDragging || _pendingLetterId != id) return;
      final position = _lastDragPosition;
      if (position == null) return;
      if (_findStarAt(position, _outerHitRadius)?.id == id) _confirm(id, position);
    });
  }

  void _confirm(int id, Offset position) {
    _resetPending();
    final selection = [...state.selectedLetterIds, id];
    emit(state.copyWith(
      selectedLetterIds: selection,
      currentDragPosition: position,
      approachingLetterIds: const [],
      clearPending: true,
      lastConnectedLetterId: id,
      releasedEarly: false,
      submittedTooSoon: false,
    ));
    _connectFeedback(selection.length);
  }

  /// Snap while on track, a soft "nope" when a wrong star connects
  void _connectFeedback(int chainLength) {
    if (state.isOnTrack) {
      AudioService.instance.playSnap(chainLength);
      HapticService.instance.snap();
    } else {
      AudioService.instance.play(GameSound.connectFail);
      HapticService.instance.error();
    }
  }

  int? get _lastSelectedId =>
      state.selectedLetterIds.isEmpty ? null : state.selectedLetterIds.last;

  LetterNode? _findStarAt(Offset position, double radius) {
    for (final star in state.letters) {
      final dx = star.position.dx - position.dx;
      final dy = star.position.dy - position.dy;
      if (dx * dx + dy * dy < radius * radius) return star;
    }
    return null;
  }

  void _resetPending() {
    _dwellTimer?.cancel();
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
  }

  // ============================================
  // BUTTONS - same rules as the game
  // ============================================

  /// DEL: clears the current word; if it's empty, removes the last
  /// finished word
  void clearSelection() {
    if (!state.hasWordContent) return;
    AudioService.instance.play(GameSound.delete);
    HapticService.instance.light();

    if (state.selectedLetterIds.isNotEmpty) {
      emit(state.copyWith(selectedLetterIds: const [], submittedTooSoon: false));
      return;
    }
    final committed = state.committedWord.trimRight();
    final lastSpace = committed.lastIndexOf(' ');
    emit(state.copyWith(
      committedWord: lastSpace == -1 ? '' : committed.substring(0, lastSpace + 1),
      submittedTooSoon: false,
    ));
  }

  /// Space: locks in the current word and starts a fresh one
  void insertSpace() {
    if (state.selectedLetterIds.isEmpty) return;
    AudioService.instance.play(GameSound.buttonTap);
    HapticService.instance.selection();
    emit(state.copyWith(
      committedWord: '${state.committedWord}${state.currentSelection} ',
      selectedLetterIds: const [],
      submittedTooSoon: false,
    ));
  }

  /// x2: repeats the last letter
  void repeatLastLetter() {
    if (state.selectedLetterIds.isEmpty) return;
    final selection = [...state.selectedLetterIds, state.selectedLetterIds.last];
    emit(state.copyWith(selectedLetterIds: selection, submittedTooSoon: false));
    _connectFeedback(selection.length);
  }

  /// GO: checks the word
  void submit() {
    if (state.phase != PracticePhase.playing || !state.hasWordContent) return;

    if (!state.isComplete) {
      AudioService.instance.play(GameSound.wordWrong);
      HapticService.instance.error();
      emit(state.copyWith(submittedTooSoon: true));
      return;
    }

    AudioService.instance.duckMusic(const Duration(milliseconds: 2200));
    AudioService.instance.play(GameSound.bubblesRise);
    AudioService.instance.playDelayed(GameSound.wordCorrect, const Duration(milliseconds: 120));
    HapticService.instance.success();
    emit(state.copyWith(phase: PracticePhase.lessonComplete));

    _advanceTimer = Timer(lessonCelebration, () {
      if (isClosed) return;
      final next = state.lessonIndex + 1;
      if (next < practiceLessons.length) {
        startLesson(next);
      } else {
        AudioService.instance.duckMusic(const Duration(seconds: 3));
        AudioService.instance.play(GameSound.roundComplete);
        emit(state.copyWith(phase: PracticePhase.finished));
      }
    });
  }

  void _cancelTimers() {
    _dwellTimer?.cancel();
    _guideTimer?.cancel();
    _advanceTimer?.cancel();
    _pendingLetterId = null;
    _pendingLetterEnteredAt = null;
    _lastDragPosition = null;
  }

  @override
  Future<void> close() {
    _cancelTimers();
    return super.close();
  }
}
