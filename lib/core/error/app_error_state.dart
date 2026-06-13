import 'dart:ui';
import 'package:equatable/equatable.dart';

abstract class AppErrorState extends Equatable {
  const AppErrorState();
  @override
  List<Object?> get props => [];
}

class AppErrorInitial extends AppErrorState {}

class TransientErrorState extends AppErrorState {
  final String message;
  final VoidCallback? onRetry;
  final int timestamp; // to ensure state changes even with same message

  const TransientErrorState({required this.message, this.onRetry, required this.timestamp});

  @override
  List<Object?> get props => [message, onRetry, timestamp];
}
