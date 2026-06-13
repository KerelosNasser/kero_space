import 'dart:ui';
import 'package:equatable/equatable.dart';

abstract class AppErrorEvent extends Equatable {
  const AppErrorEvent();
  @override
  List<Object?> get props => [];
}

class TransientErrorOccurred extends AppErrorEvent {
  final String message;
  final VoidCallback? onRetry;

  const TransientErrorOccurred({required this.message, this.onRetry});

  @override
  List<Object?> get props => [message, onRetry];
}
