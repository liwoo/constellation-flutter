import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:constellation_app/shared/services/services.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState(
    soundEnabled: AudioService.instance.soundEnabled,
    hapticsEnabled: HapticService.instance.hapticsEnabled,
  ));

  /// Toggle sound effects on/off
  void toggleSound() {
    AudioService.instance.toggleSound();
    emit(state.copyWith(soundEnabled: AudioService.instance.soundEnabled));
  }

  /// Toggle haptic feedback on/off
  void toggleHaptics() {
    HapticService.instance.toggleHaptics();
    emit(state.copyWith(hapticsEnabled: HapticService.instance.hapticsEnabled));
  }

  /// Set sound enabled state directly
  void setSoundEnabled(bool enabled) {
    AudioService.instance.setSoundEnabled(enabled);
    emit(state.copyWith(soundEnabled: enabled));
  }

  /// Set haptics enabled state directly
  void setHapticsEnabled(bool enabled) {
    HapticService.instance.setHapticsEnabled(enabled);
    emit(state.copyWith(hapticsEnabled: enabled));
  }
}
