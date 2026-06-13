import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../bloc/telemetry_bloc.dart';
import '../bloc/telemetry_event.dart';
import '../bloc/telemetry_state.dart';
import '../widgets/heatmap_painter.dart';

class UnlockHeatmapScreen extends StatefulWidget {
  const UnlockHeatmapScreen({super.key});
  @override State<UnlockHeatmapScreen> createState() => _State();
}

class _State extends State<UnlockHeatmapScreen> {
  late DateTime _weekStart;
  int? _selDay, _selHour;
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final mon = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(mon.year, mon.month, mon.day);
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<TelemetryBloc>().add(LoadUnlockHeatmap(_weekStart)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelemetryBloc, TelemetryState>(builder: (context, state) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Unlock Patterns', style: Theme.of(context).textTheme.titleMedium),
          Text('Tap a cell to see unlock count for that hour.',
              style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 16),
          // hour labels
          Row(children: [
            const SizedBox(width: 36),
            ...List.generate(24, (h) => Expanded(child: h % 6 == 0
                ? Text('${h}h', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 9))
                : const SizedBox())),
          ]),
          const SizedBox(height: 4),
          ...List.generate(7, (d) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              SizedBox(width: 36, child: Text(_days[d],
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
              Expanded(child: SizedBox(height: 28,
                child: state.unlockHeatmap.isEmpty
                    ? Container(color: AppTheme.bgElevated)
                    : HeatmapGrid(
                        matrix: [state.unlockHeatmap[d]],
                        onCellTap: (_, col) => setState(() { _selDay = d; _selHour = col; }),
                      ),
              )),
            ]),
          )),
          const SizedBox(height: 16),
          if (_selDay != null && _selHour != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.lock_open, color: AppTheme.accentCyan),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${_days[_selDay!]} at ${_selHour.toString().padLeft(2,'0')}:00',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Text(
                    '${state.unlockHeatmap.isNotEmpty ? state.unlockHeatmap[_selDay!][_selHour!] : 0} unlocks',
                    style: Theme.of(context).textTheme.labelSmall!.copyWith(color: AppTheme.textSecondary),
                  ),
                ]),
              ]),
            ),
        ]),
      );
    });
  }
}
