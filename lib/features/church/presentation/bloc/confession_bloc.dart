import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:cryptography/cryptography.dart';
import '../../data/repositories/confession_crypto_service.dart';

// Events
abstract class ConfessionEvent extends Equatable {
  const ConfessionEvent();
  @override
  List<Object?> get props => [];
}

class UnlockConfessionSession extends ConfessionEvent {
  final String passphrase;
  const UnlockConfessionSession(this.passphrase);
  @override
  List<Object?> get props => [passphrase];
}

class LockConfessionSession extends ConfessionEvent {}
class SessionActivityDetected extends ConfessionEvent {}

// States
abstract class ConfessionState extends Equatable {
  const ConfessionState();
  @override
  List<Object?> get props => [];
}

class ConfessionLocked extends ConfessionState {}

class ConfessionUnlocking extends ConfessionState {}

class ConfessionUnlocked extends ConfessionState {
  final SecretKey sessionKey;
  const ConfessionUnlocked(this.sessionKey);
  @override
  List<Object?> get props => [sessionKey];
}

class ConfessionUnlockFailed extends ConfessionState {}

// Bloc
class ConfessionBloc extends Bloc<ConfessionEvent, ConfessionState> {
  final ConfessionCryptoService _cryptoService;
  Timer? _idleTimer;

  ConfessionBloc(this._cryptoService) : super(ConfessionLocked()) {
    on<UnlockConfessionSession>((event, emit) async {
      emit(ConfessionUnlocking());
      try {
        final key = await _cryptoService.deriveKey(event.passphrase);
        _resetIdleTimer();
        emit(ConfessionUnlocked(key));
      } catch (e) {
        emit(ConfessionUnlockFailed());
      }
    });

    on<LockConfessionSession>((event, emit) {
      _idleTimer?.cancel();
      emit(ConfessionLocked());
    });

    on<SessionActivityDetected>((event, emit) {
      if (state is ConfessionUnlocked) {
        _resetIdleTimer();
      }
    });
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(const Duration(minutes: 10), () {
      add(LockConfessionSession());
    });
  }

  @override
  Future<void> close() {
    _idleTimer?.cancel();
    return super.close();
  }
}
