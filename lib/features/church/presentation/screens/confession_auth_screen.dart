import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/confession_bloc.dart';

class ConfessionAuthScreen extends StatefulWidget {
  const ConfessionAuthScreen({super.key});

  @override
  State<ConfessionAuthScreen> createState() => _ConfessionAuthScreenState();
}

class _ConfessionAuthScreenState extends State<ConfessionAuthScreen> {
  final TextEditingController _passphraseController = TextEditingController();
  bool _enableBiometricsCheckbox = false;
  bool _biometricsPrompted = false;
  bool _autoBiometricsTriggered = false;

  @override
  void initState() {
    super.initState();
    context.read<ConfessionBloc>().add(CheckBiometricStatus());
  }

  @override
  void dispose() {
    _passphraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConfessionBloc, ConfessionState>(
        listener: (context, state) {
          if (state is ConfessionLocked) {
            if (state.isBiometricAvailable &&
                !state.isBiometricEnabled &&
                !_biometricsPrompted) {
              setState(() {
                _enableBiometricsCheckbox = true;
                _biometricsPrompted = true;
              });
            }
            if (state.isBiometricEnabled && !_autoBiometricsTriggered) {
              setState(() {
                _autoBiometricsTriggered = true;
              });
              context.read<ConfessionBloc>().add(UnlockWithBiometrics());
            }
          } else if (state is ConfessionUnlocked) {
            if (_enableBiometricsCheckbox) {
              context.read<ConfessionBloc>().add(
                EnableBiometrics(_passphraseController.text),
              );
            }
            context.go('/church/confessions_log');
          } else if (state is ConfessionUnlockFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to unlock. Wrong passphrase?'),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ConfessionUnlocking) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentViolet),
            );
          }
          final isLocked = state is ConfessionLocked;
          final biometricAvailable = isLocked && state.isBiometricAvailable;
          final biometricEnabled = isLocked && state.isBiometricEnabled;

          final titleText = biometricEnabled
              ? 'Use biometrics to unlock'
              : 'Enter Passphrase';
          final subtitleText = biometricEnabled
              ? 'Use your fingerprint or face to access your confessions.'
              : 'Your confessions are encrypted locally using AES-256-GCM. The key is never stored.';

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(height: 32),
                Text(
                  titleText,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                if (!biometricEnabled)
                  TextField(
                    controller: _passphraseController,
                    obscureText: true,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Passphrase',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: biometricEnabled
                          ? IconButton(
                              icon: const Icon(
                                Icons.fingerprint,
                                color: AppTheme.accentViolet,
                                size: 28,
                              ),
                              onPressed: () {
                                context.read<ConfessionBloc>().add(
                                  UnlockWithBiometrics(),
                                );
                              },
                            )
                          : null,
                    ),
                  ),
                if (biometricAvailable && !biometricEnabled)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _enableBiometricsCheckbox,
                          activeColor: AppTheme.accentViolet,
                          onChanged: (val) {
                            setState(() {
                              _enableBiometricsCheckbox = val ?? false;
                            });
                          },
                        ),
                        const Text(
                          'Use biometrics next time',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                if (biometricEnabled)
                  SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.fingerprint, size: 24),
                      label: const Text(
                        'Unlock with biometrics',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentViolet,
                        foregroundColor: AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        context.read<ConfessionBloc>().add(
                          UnlockWithBiometrics(),
                        );
                      },
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentViolet,
                              foregroundColor: AppTheme.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              if (_passphraseController.text.isNotEmpty) {
                                context.read<ConfessionBloc>().add(
                                  UnlockConfessionSession(
                                    _passphraseController.text,
                                  ),
                                );
                              }
                            },
                            child: const Text(
                              'Unlock',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (biometricEnabled) ...[
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.bgSurface,
                              foregroundColor: AppTheme.accentViolet,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppTheme.accentViolet,
                                  width: 1.5,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () {
                              context.read<ConfessionBloc>().add(
                                UnlockWithBiometrics(),
                              );
                            },
                            child: const Icon(Icons.fingerprint, size: 28),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          );
        },
      );
  }
}
