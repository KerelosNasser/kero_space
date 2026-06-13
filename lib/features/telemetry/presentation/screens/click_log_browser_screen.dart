import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/click_log_entry_tile.dart';

class ClickLogBrowserScreen extends StatefulWidget {
  const ClickLogBrowserScreen({super.key});
  @override State<ClickLogBrowserScreen> createState() => _State();
}

class _State extends State<ClickLogBrowserScreen> {
  final _scroll = ScrollController();
  String? _pkgFilter;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    context.read<TelemetryBloc>().add(const LoadClickLogs());
  }

  void _onScroll() {
    final s = context.read<TelemetryBloc>().state;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200
        && s.clickLogHasMore && s.status != TelemetryStatus.loading) {
      context.read<TelemetryBloc>().add(LoadClickLogs(packageFilter: _pkgFilter, page: s.clickLogPage + 1));
    }
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onSubmitted: (v) {
              setState(() => _pkgFilter = v.isEmpty ? null : v);
              context.read<TelemetryBloc>().add(LoadClickLogs(packageFilter: _pkgFilter));
            },
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filter by package...',
              prefixIcon: const Icon(Icons.filter_list, color: AppTheme.textSecondary),
              filled: true, fillColor: AppTheme.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(child: state.clickLogs.isEmpty
            ? const Center(child: Text('No click logs yet', style: TextStyle(color: AppTheme.textSecondary)))
            : ListView.builder(
                controller: _scroll,
                itemCount: state.clickLogs.length + (state.clickLogHasMore ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == state.clickLogs.length) {
                    return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
                  }
                  return ClickLogEntryTile(event: state.clickLogs[i]);
                },
              )),
      ]);
    });
  }
}
