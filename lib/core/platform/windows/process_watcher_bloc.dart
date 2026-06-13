import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'process_watcher_event.dart';
import 'process_watcher_state.dart';

class ProcessWatcherBloc extends Bloc<ProcessWatcherEvent, ProcessWatcherState> with WindowListener {
  Timer? _pollingTimer;
  late final DynamicLibrary _user32;
  late final int Function() _getForegroundWindow;
  late final int Function(int, Pointer<Uint16>, int) _getWindowText;
  bool _isFfiAvailable = false;
  String _lastTitle = '';

  ProcessWatcherBloc() : super(ProcessWatcherInitial()) {
    on<ProcessWatcherStarted>(_onStarted);
    on<ProcessTitlePolled>(_onTitlePolled);
    
    windowManager.addListener(this);
    
    try {
      _user32 = DynamicLibrary.open('user32.dll');
      _getForegroundWindow = _user32.lookupFunction<
          IntPtr Function(),
          int Function()>('GetForegroundWindow');
      _getWindowText = _user32.lookupFunction<
          Int32 Function(IntPtr, Pointer<Uint16>, Int32),
          int Function(int, Pointer<Uint16>, int)>('GetWindowTextW');
      _isFfiAvailable = true;
    } catch (e) {
      _isFfiAvailable = false;
    }
  }

  void _onStarted(ProcessWatcherStarted event, Emitter<ProcessWatcherState> emit) {
    if (!_isFfiAvailable) {
      emit(const ProcessWatcherUnavailable('FFI or user32.dll not available'));
      return;
    }
    _startPolling();
  }

  void _onTitlePolled(ProcessTitlePolled event, Emitter<ProcessWatcherState> emit) {
    emit(ProcessChanged(event.title));
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _poll() {
    if (!_isFfiAvailable) return;
    final buf = calloc<Uint16>(256);
    try {
      final hwnd = _getForegroundWindow();
      _getWindowText(hwnd, buf, 256);
      final title = buf.cast<Utf16>().toDartString();
      if (title.isNotEmpty && title != _lastTitle) {
        _lastTitle = title;
        add(ProcessTitlePolled(title));
      }
    } catch (e) {
      add(const ProcessTitlePolled('Error reading window'));
    } finally {
      calloc.free(buf);
    }
  }

  @override
  void onWindowMinimize() {
    _stopPolling();
  }

  @override
  void onWindowRestore() {
    if (_isFfiAvailable) _startPolling();
  }

  @override
  void onWindowFocus() {
    if (_isFfiAvailable && _pollingTimer == null) _startPolling();
  }

  @override
  Future<void> close() {
    windowManager.removeListener(this);
    _stopPolling();
    return super.close();
  }
}
