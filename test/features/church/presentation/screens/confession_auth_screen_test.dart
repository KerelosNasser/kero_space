import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_platform_interface/local_auth_platform_interface.dart';
import 'package:kero_space/features/church/data/repositories/confession_crypto_service.dart';
import 'package:kero_space/features/church/presentation/bloc/confession_bloc.dart';
import 'package:kero_space/features/church/presentation/screens/confession_auth_screen.dart';

class StubSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {
    'confession_biometric_passphrase': 'test_passphrase',
  };

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }
}

class StubLocalAuth extends Fake implements LocalAuthentication {
  @override
  Future<bool> get canCheckBiometrics async => true;
  @override
  Future<bool> isDeviceSupported() async => true;
  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<AuthMessages> authMessages = const <AuthMessages>[],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async => false;
}

void main() {
  testWidgets('shows biometric unlock when biometrics are enabled', (
    tester,
  ) async {
    final bloc = ConfessionBloc(
      ConfessionCryptoService(
        secureStorage: StubSecureStorage(),
        localAuth: StubLocalAuth(),
      ),
    );

    await tester.pumpWidget(
      BlocProvider<ConfessionBloc>.value(
        value: bloc,
        child: const MaterialApp(home: ConfessionAuthScreen()),
      ),
    );

    bloc.emit(
      const ConfessionLocked(
        isBiometricAvailable: true,
        isBiometricEnabled: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Use biometrics to unlock'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
