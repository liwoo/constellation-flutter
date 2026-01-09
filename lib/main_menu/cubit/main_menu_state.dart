part of 'main_menu_cubit.dart';

/// {@template main_menu}
/// MainMenuState description
/// {@endtemplate}
class MainMenuState extends Equatable {
  /// {@macro main_menu}
  const MainMenuState({
    this.customProperty = 'Default Value',
  });

  /// A description for customProperty
  final String customProperty;

  @override
  List<Object> get props => [customProperty];

  /// Creates a copy of the current MainMenuState with property changes
  MainMenuState copyWith({
    String? customProperty,
  }) {
    return MainMenuState(
      customProperty: customProperty ?? this.customProperty,
    );
  }
}
/// {@template main_menu_initial}
/// The initial state of MainMenuState
/// {@endtemplate}
class MainMenuInitial extends MainMenuState {
  /// {@macro main_menu_initial}
  const MainMenuInitial() : super();
}
