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
    final colors = context.appColors;
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      return Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onSubmitted: (v) {
              setState(() => _pkgFilter = v.isEmpty ? null : v);
              context.read<TelemetryBloc>().add(LoadClickLogs(packageFilter: _pkgFilter));
            },
            style: TextStyle(color: colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Filter by package...',
              prefixIcon: Icon(Icons.filter_list, color: colors.textSecondary),
              filled: true,
              fillColor: colors.bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: state.clickLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 56, color: colors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'No click logs recorded',
                        style: TextStyle(color: colors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Accessibility interaction events will appear here.',
                        style: TextStyle(color: colors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  itemCount: state.clickLogs.length + (state.clickLogHasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == state.clickLogs.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: CircularProgressIndicator(color: colors.domainTelemetry),
                        ),
                      );
                    }
                    return ClickLogEntryTile(event: state.clickLogs[i]);
                  },
                ),
        ),
      ]);
    });
  }
}
