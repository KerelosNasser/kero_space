import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import 'app_error_bloc.dart';
import 'app_error_state.dart';

class ErrorSnackbarListener extends StatelessWidget {
  final Widget child;

  const ErrorSnackbarListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppErrorBloc, AppErrorState>(
      listener: (context, state) {
        if (state is TransientErrorState) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.hideCurrentSnackBar();
          
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: AppTheme.accentRose,
              content: Text(
                state.message,
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              action: state.onRetry != null
                  ? SnackBarAction(
                      label: 'RETRY',
                      textColor: AppTheme.textPrimary,
                      onPressed: state.onRetry!,
                    )
                  : null,
            ),
          );
        }
      },
      child: child,
    );
  }
}
