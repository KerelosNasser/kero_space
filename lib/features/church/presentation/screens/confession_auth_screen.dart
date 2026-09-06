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
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      body: SafeArea(
        child: BlocConsumer<ConfessionBloc, ConfessionState>(
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
                SnackBar(
                  content: const Text('Failed to unlock. Wrong passphrase?'),
                  backgroundColor: colors.accentError,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ConfessionUnlocking) {
              return Center(
                child: CircularProgressIndicator(color: colors.domainChurch),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: colors.domainChurch,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    titleText,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitleText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!biometricEnabled)
                    TextField(
                      controller: _passphraseController,
                      obscureText: true,
                      style: TextStyle(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Passphrase',
                        hintStyle: TextStyle(color: colors.textSecondary),
                        filled: true,
                        fillColor: colors.bgElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.borderSubtle),
                        ),
                      ),
                    ),
                  if (biometricAvailable && !biometricEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _enableBiometricsCheckbox,
                            activeColor: colors.domainChurch,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            onChanged: (val) {
                              setState(() {
                                _enableBiometricsCheckbox = val ?? false;
                              });
                            },
                          ),
                          Text(
                            'Use biometrics next time',
                            style: TextStyle(
                              color: colors.textSecondary,
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
                          backgroundColor: colors.domainChurch,
                          foregroundColor: Colors.white,
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
                    SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.domainChurch,
                          foregroundColor: Colors.white,
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
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
