import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kero_space/features/church/data/repositories/confession_crypto_service.dart';
import 'package:kero_space/features/church/presentation/bloc/confession_bloc.dart';
import 'package:kero_space/features/church/presentation/screens/confession_auth_screen.dart';

class StubSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

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

void main() {
  testWidgets('shows biometric unlock when biometrics are enabled', (
    tester,
  ) async {
    final bloc = ConfessionBloc(
      ConfessionCryptoService(secureStorage: StubSecureStorage()),
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
    await tester.pump();

    expect(find.text('Use biometrics to unlock'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
