import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_error_event.dart';
import 'app_error_state.dart';

class AppErrorBloc extends Bloc<AppErrorEvent, AppErrorState> {
  AppErrorBloc() : super(AppErrorInitial()) {
    on<TransientErrorOccurred>(_onTransientError);
  }

  void _onTransientError(TransientErrorOccurred event, Emitter<AppErrorState> emit) {
    emit(TransientErrorState(
      message: event.message,
      onRetry: event.onRetry,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ));
  }
}
