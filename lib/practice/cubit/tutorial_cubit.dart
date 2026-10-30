import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:constellation_app/game/cubit/game_cubit.dart';
import 'package:constellation_app/game/widgets/coach_targets.dart';
import 'package:constellation_app/shared/constants/constants.dart';

/// One coach mark in the practice tutorial.
///
/// [target] is the UI the spotlight frames (null = centered card).
/// [requiresAction] steps wait for the player to actually do the thing,
/// with touches allowed through the spotlight only; the rest are read and
/// dismissed with a button.
enum TutorialStep {
  welcome(null, requiresAction: false),
  spinWheel(CoachTarget.wheel, requiresAction: true),
  previewWords(CoachTarget.constellation, requiresAction: false),
  startLetter(CoachTarget.startBadge, requiresAction: false),
  category(CoachTarget.category, requiresAction: false),
  timer(CoachTarget.timer, requiresAction: false),
  drag(CoachTarget.constellation, requiresAction: true),
  submit(CoachTarget.go, requiresAction: true),
  wrongAnswer(CoachTarget.del, requiresAction: false),
  space(CoachTarget.space, requiresAction: false),
  doubleLetters(CoachTarget.x2, requiresAction: false),
  hint(CoachTarget.hint, requiresAction: true),
  mysteryOrb(CoachTarget.constellation, requiresAction: false),
  skip(CoachTarget.skip, requiresAction: false),
  pause(CoachTarget.pause, requiresAction: false);

  const TutorialStep(this.target, {required this.requiresAction});

  final CoachTarget? target;
  final bool requiresAction;
}

class TutorialState extends Equatable {
  const TutorialState({
    this.step,
    this.completed = const {},
    this.dismissed = false,
  });

  /// Coach mark on screen right now (null = free play)
  final TutorialStep? step;
  final Set<TutorialStep> completed;

  /// Player chose to skip the rest of the tutorial
  final bool dismissed;

  @override
  List<Object?> get props => [step, completed, dismissed];
}

/// Drives the practice coach marks by watching the real game.
///
/// Each category of the scripted practice letter introduces one mechanic.
/// While a coach mark is up the game clock is held, so learning never
/// costs time.
class TutorialCubit extends Cubit<TutorialState> {
  TutorialCubit(this._game) : super(const TutorialState()) {
    _subscription = _game.stream.listen(_onGameState);
    _onGameState(_game.state);
  }

  final GameCubit _game;
  StreamSubscription<GameState>? _subscription;
  GameState? _previous;

  // Coach marks wait for the opening star shimmer to finish
  Timer? _previewTimer;
  String? _watchedCategory;
  String? _readyCategory;

  String _categoryKey(GameState s) => '${s.currentLetter}-${s.categoryIndex}';

  void _onGameState(GameState game) {
    final previous = _previous;
    _previous = game;

    // A fresh run (first launch or restart) replays the whole tutorial
    if (game.phase == GamePhase.spinningWheel &&
        previous?.phase != GamePhase.spinningWheel) {
      _reset();
    }

    _checkActionDone(game);

    // Coach marks only make sense while playing
    if (state.step != null && !_isCoachable(game)) {
      _setStep(null);
    }

    // First miss gets explained once
    if (game.lastAnswerCorrect == false &&
        previous?.lastAnswerCorrect != false &&
        state.step == null &&
        !state.dismissed &&
        !state.completed.contains(TutorialStep.wrongAnswer)) {
      _setStep(TutorialStep.wrongAnswer);
    }

    _watchForPreview(game);
    _advance();
  }

  bool _isCoachable(GameState game) =>
      game.phase == GamePhase.spinningWheel ||
      game.phase == GamePhase.playingRound;

  /// Action steps complete when the player does the thing
  void _checkActionDone(GameState game) {
    final done = switch (state.step) {
      TutorialStep.spinWheel => game.phase != GamePhase.spinningWheel,
      TutorialStep.drag => !game.isDragging && game.selectedLetterIds.length >= 2,
      TutorialStep.submit => game.lastAnswerCorrect != null,
      TutorialStep.hint => game.hintWord != null,
      _ => false,
    };
    if (done) _completeCurrent();
  }

  void _watchForPreview(GameState game) {
    if (game.phase != GamePhase.playingRound) return;
    final key = _categoryKey(game);
    if (key == _watchedCategory) return;
    _watchedCategory = key;
    _previewTimer?.cancel();
    _previewTimer = Timer(
      Duration(milliseconds: WordPreviewConfig.totalMs(game.previewPaths) + 250),
      () {
        if (isClosed) return;
        _readyCategory = key;
        _advance();
      },
    );
  }

  /// Steps introduced by the current point in the practice letter
  List<TutorialStep> _stepsFor(GameState game) {
    if (game.phase == GamePhase.spinningWheel) {
      return const [TutorialStep.welcome, TutorialStep.spinWheel];
    }
    if (game.phase != GamePhase.playingRound ||
        game.isPaused ||
        _readyCategory != _categoryKey(game)) {
      return const [];
    }
    return switch (game.categoryIndex) {
      0 => const [
          TutorialStep.previewWords,
          TutorialStep.startLetter,
          TutorialStep.category,
          TutorialStep.timer,
          TutorialStep.drag,
          TutorialStep.submit,
        ],
      1 => const [TutorialStep.space],
      2 => const [TutorialStep.doubleLetters],
      3 => const [TutorialStep.hint],
      4 => const [TutorialStep.mysteryOrb, TutorialStep.skip, TutorialStep.pause],
      _ => const [],
    };
  }

  void _advance() {
    if (state.step != null || state.dismissed) return;
    final game = _game.state;

    for (final step in _stepsFor(game)) {
      if (state.completed.contains(step)) continue;
      if (step == TutorialStep.hint && !_canUseHint(game)) {
        // Out of hints or time - nothing to press, so skip the lesson
        _markCompleted(step);
        continue;
      }
      _setStep(step);
      if (step == TutorialStep.drag) showMe();
      return;
    }
  }

  bool _canUseHint(GameState game) =>
      game.hintsRemaining > 0 &&
      game.hintWord == null &&
      game.timeRemaining >= TimeConfig.minTimeForHint;

  /// Example answer for the category being taught
  String? get exampleWord {
    final index = _game.state.categoryIndex;
    if (index < 0 || index >= PracticeConfig.exampleWords.length) return null;
    return PracticeConfig.exampleWords[index];
  }

  /// Replay the example word's path across the stars
  void showMe() {
    final word = exampleWord;
    if (word != null) _game.showGuidedPath(word);
  }

  /// Dismiss a read-only coach mark
  void next() {
    final step = state.step;
    if (step == null || step.requiresAction) return;
    _completeCurrent();
    _advance();
  }

  /// Stop coaching; the rest of practice is free play
  void dismiss() {
    emit(TutorialState(completed: state.completed, dismissed: true));
    _game.setTimerHeld(false);
  }

  void _completeCurrent() {
    final step = state.step;
    if (step == null) return;
    _markCompleted(step);
    _setStep(null);
  }

  void _markCompleted(TutorialStep step) {
    emit(TutorialState(
      step: state.step,
      completed: {...state.completed, step},
      dismissed: state.dismissed,
    ));
  }

  void _setStep(TutorialStep? step) {
    emit(TutorialState(
      step: step,
      completed: state.completed,
      dismissed: state.dismissed,
    ));
    // Learning never costs time
    _game.setTimerHeld(step != null);
  }

  void _reset() {
    _previewTimer?.cancel();
    _watchedCategory = null;
    _readyCategory = null;
    emit(const TutorialState());
    _game.setTimerHeld(false);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _previewTimer?.cancel();
    _game.setTimerHeld(false);
    return super.close();
  }
}
