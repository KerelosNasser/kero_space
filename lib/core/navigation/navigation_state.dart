import 'package:equatable/equatable.dart';
import 'navigation_mode.dart';

class NavigationState extends Equatable {
  final AppNavStyle mode;

  const NavigationState({required this.mode});

  factory NavigationState.initial() {
    return const NavigationState(mode: AppNavStyle.commandCapsule);
  }

  NavigationState copyWith({AppNavStyle? mode}) {
    return NavigationState(mode: mode ?? this.mode);
  }

  @override
  List<Object?> get props => [mode];
}
