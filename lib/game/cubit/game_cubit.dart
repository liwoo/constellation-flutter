import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  GameCubit() : super(const GameInitial()) {
    _initializeGame();
  }

  Timer? _timer;

  void _initializeGame() {
    // Initialize with sample letters in constellation pattern
    final letters = [
      const LetterNode(id: 0, letter: 'N', points: 1, position: Offset(0.15, 0.08)),
      const LetterNode(id: 1, letter: 'I', points: 1, position: Offset(0.38, 0.08)),
      const LetterNode(id: 2, letter: 'K', points: 5, position: Offset(0.62, 0.08)),
      const LetterNode(id: 3, letter: 'E', points: 1, position: Offset(0.85, 0.08)),
      const LetterNode(id: 4, letter: 'W', points: 4, position: Offset(0.12, 0.28)),
      const LetterNode(id: 5, letter: 'R', points: 1, position: Offset(0.42, 0.25)),
      const LetterNode(id: 6, letter: 'D', points: 2, position: Offset(0.72, 0.27)),
      const LetterNode(id: 7, letter: 'B', points: 3, position: Offset(0.08, 0.48)),
      const LetterNode(id: 8, letter: 'F', points: 4, position: Offset(0.28, 0.46)),
      const LetterNode(id: 9, letter: 'L', points: 1, position: Offset(0.50, 0.44)),
      const LetterNode(id: 10, letter: 'H', points: 4, position: Offset(0.72, 0.48)),
      const LetterNode(id: 11, letter: 'J', points: 8, position: Offset(0.92, 0.46)),
      const LetterNode(id: 12, letter: 'U', points: 1, position: Offset(0.10, 0.68)),
      const LetterNode(id: 13, letter: 'G', points: 2, position: Offset(0.30, 0.66)),
      const LetterNode(id: 14, letter: 'M', points: 3, position: Offset(0.55, 0.70)),
      const LetterNode(id: 15, letter: 'Z', points: 10, position: Offset(0.78, 0.68)),
      const LetterNode(id: 16, letter: 'O', points: 1, position: Offset(0.92, 0.70)),
    ];

    emit(state.copyWith(
      letters: letters,
      timeRemaining: 60,
      isPlaying: true,
    ));
  }

  // Hit detection radius (relative to container size)
  static const double _hitRadius = 0.08;

  /// Start dragging from a position - check if it hits a letter
  void startDrag(Offset relativePosition) {
    final hitNode = _findNodeAtPosition(relativePosition);
    if (hitNode != null) {
      emit(state.copyWith(
        isDragging: true,
        selectedLetterIds: [hitNode.id],
        currentDragPosition: relativePosition,
      ));
    }
  }

  /// Update drag position and check for new letter hits
  void updateDrag(Offset relativePosition) {
    if (!state.isDragging) return;

    final hitNode = _findNodeAtPosition(relativePosition);

    if (hitNode != null) {
      // Check if it's not the immediately previous selection
      // (allow same letter to be added again if not consecutive)
      final lastSelectedId = state.selectedLetterIds.isNotEmpty
          ? state.selectedLetterIds.last
          : null;

      if (hitNode.id != lastSelectedId) {
        // Add to selection (even if it was selected before, just not consecutively)
        final newSelection = [...state.selectedLetterIds, hitNode.id];
        emit(state.copyWith(
          selectedLetterIds: newSelection,
          currentDragPosition: relativePosition,
        ));
      } else {
        // Same as last, just update position
        emit(state.copyWith(currentDragPosition: relativePosition));
      }
    } else {
      // No hit, just update drag position for the trailing line
      emit(state.copyWith(currentDragPosition: relativePosition));
    }
  }

  /// End dragging - keep selection intact so user can tap GO or DEL
  void endDrag() {
    emit(state.copyWith(
      isDragging: false,
      clearDragPosition: true,
    ));
  }

  /// Find a letter node at the given relative position
  LetterNode? _findNodeAtPosition(Offset position) {
    for (final node in state.letters) {
      final dx = (node.position.dx - position.dx).abs();
      final dy = (node.position.dy - position.dy).abs();
      final distance = (dx * dx + dy * dy);
      if (distance < _hitRadius * _hitRadius) {
        return node;
      }
    }
    return null;
  }

  void selectLetter(int letterId) {
    // Check if it's the last one (then deselect)
    if (state.selectedLetterIds.isNotEmpty &&
        state.selectedLetterIds.last == letterId) {
      final newSelection = List<int>.from(state.selectedLetterIds)..removeLast();
      emit(state.copyWith(selectedLetterIds: newSelection));
      return;
    }

    // Add to selection (allow duplicates, just not consecutive)
    final newSelection = [...state.selectedLetterIds, letterId];
    emit(state.copyWith(selectedLetterIds: newSelection));
  }

  void clearSelection() {
    emit(state.copyWith(selectedLetterIds: [], clearDragPosition: true));
  }

  void submitWord() {
    if (state.currentWord.length >= 2) {
      final word = state.currentWord;
      final newWords = [...state.completedWords, word];
      // Calculate score based on selected letters
      final wordScore = state.selectedLetters.fold<int>(0, (sum, l) => sum + l.points);
      emit(state.copyWith(
        completedWords: newWords,
        selectedLetterIds: [],
        score: state.score + wordScore,
      ));
    }
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.timeRemaining > 0) {
        emit(state.copyWith(timeRemaining: state.timeRemaining - 1));
      } else {
        _timer?.cancel();
        emit(state.copyWith(isPlaying: false));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
