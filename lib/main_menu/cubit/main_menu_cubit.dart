import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
part 'main_menu_state.dart';

class MainMenuCubit extends Cubit<MainMenuState> {
  MainMenuCubit() : super(const MainMenuInitial());

  void toggleSound() {
    emit(state.copyWith(soundEnabled: !state.soundEnabled));
  }

  void updatePlayerName(String name) {
    emit(state.copyWith(playerName: name));
  }

  void updateHighScore(int score) {
    if (score > state.highScore) {
      emit(state.copyWith(highScore: score));
    }
  }

  void incrementGamesPlayed() {
    emit(state.copyWith(gamesPlayed: state.gamesPlayed + 1));
  }
}
