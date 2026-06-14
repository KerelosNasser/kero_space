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

class CheckBiometricStatus extends ConfessionEvent {}

class UnlockConfessionSession extends ConfessionEvent {
  final String passphrase;
  const UnlockConfessionSession(this.passphrase);
  @override
  List<Object?> get props => [passphrase];
}

class UnlockWithBiometrics extends ConfessionEvent {}

class EnableBiometrics extends ConfessionEvent {
  final String passphrase;
  const EnableBiometrics(this.passphrase);
  @override
  List<Object?> get props => [passphrase];
}

class DisableBiometrics extends ConfessionEvent {}

class LockConfessionSession extends ConfessionEvent {}

class SessionActivityDetected extends ConfessionEvent {}

// States
abstract class ConfessionState extends Equatable {
  const ConfessionState();
  @override
  List<Object?> get props => [];
}

class ConfessionLocked extends ConfessionState {
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;

  const ConfessionLocked({
    this.isBiometricAvailable = false,
    this.isBiometricEnabled = false,
  });

  @override
  List<Object?> get props => [isBiometricAvailable, isBiometricEnabled];
}

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

  ConfessionBloc(this._cryptoService) : super(const ConfessionLocked()) {
    on<CheckBiometricStatus>((event, emit) async {
      final available = await _cryptoService.isBiometricsAvailable();
      final enabled = await _cryptoService.isBiometricsEnabled();
      emit(ConfessionLocked(isBiometricAvailable: available, isBiometricEnabled: enabled));
    });

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

    on<UnlockWithBiometrics>((event, emit) async {
      emit(ConfessionUnlocking());
      try {
        final passphrase = await _cryptoService.retrievePassphraseWithBiometrics();
        if (passphrase != null) {
          final key = await _cryptoService.deriveKey(passphrase);
          _resetIdleTimer();
          emit(ConfessionUnlocked(key));
        } else {
          final available = await _cryptoService.isBiometricsAvailable();
          final enabled = await _cryptoService.isBiometricsEnabled();
          emit(ConfessionLocked(isBiometricAvailable: available, isBiometricEnabled: enabled));
        }
      } catch (e) {
        emit(ConfessionUnlockFailed());
      }
    });

    on<EnableBiometrics>((event, emit) async {
      await _cryptoService.savePassphrase(event.passphrase);
      final available = await _cryptoService.isBiometricsAvailable();
      emit(ConfessionLocked(isBiometricAvailable: available, isBiometricEnabled: true));
    });

    on<DisableBiometrics>((event, emit) async {
      await _cryptoService.disableBiometrics();
      final available = await _cryptoService.isBiometricsAvailable();
      emit(ConfessionLocked(isBiometricAvailable: available, isBiometricEnabled: false));
    });

    on<LockConfessionSession>((event, emit) async {
      _idleTimer?.cancel();
      final available = await _cryptoService.isBiometricsAvailable();
      final enabled = await _cryptoService.isBiometricsEnabled();
      emit(ConfessionLocked(isBiometricAvailable: available, isBiometricEnabled: enabled));
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
