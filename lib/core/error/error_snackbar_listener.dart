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
        final colors = context.appColors;
        if (state is TransientErrorState) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.hideCurrentSnackBar();
          
          scaffoldMessenger.showSnackBar(
            SnackBar(
              backgroundColor: colors.accentError,
              content: Text(
                state.message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              action: state.onRetry != null
                  ? SnackBarAction(
                      label: 'RETRY',
                      textColor: Colors.white,
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
