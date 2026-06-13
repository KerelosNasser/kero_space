import 'package:equatable/equatable.dart';
import '../../data/models/blacklist_rule.dart';

abstract class TelemetryEvent extends Equatable {
  const TelemetryEvent();
  @override List<Object?> get props => [];
}

class LoadTelemetryDashboard extends TelemetryEvent {}
class LoadUnlockHeatmap extends TelemetryEvent {
  final DateTime weekStart;
  const LoadUnlockHeatmap(this.weekStart);
  @override List<Object?> get props => [weekStart];
}
class LoadBlockerStats extends TelemetryEvent {}
class LoadClickLogs extends TelemetryEvent {
  final String? packageFilter;
  final DateTime? from;
  final DateTime? to;
  final int page;
  const LoadClickLogs({this.packageFilter, this.from, this.to, this.page = 0});
  @override List<Object?> get props => [packageFilter, from, to, page];
}
class LoadBlacklist extends TelemetryEvent {}
class AddBlacklistRule extends TelemetryEvent {
  final BlacklistRule rule;
  const AddBlacklistRule(this.rule);
  @override List<Object?> get props => [rule];
}
class RemoveBlacklistRule extends TelemetryEvent {
  final String packageName;
  const RemoveBlacklistRule(this.packageName);
  @override List<Object?> get props => [packageName];
}
class UpdateBlacklistRule extends TelemetryEvent {
  final BlacklistRule rule;
  const UpdateBlacklistRule(this.rule);
  @override List<Object?> get props => [rule];
}
class ToggleAgent extends TelemetryEvent {
  final String agentId;
  final bool enabled;
  const ToggleAgent(this.agentId, this.enabled);
  @override List<Object?> get props => [agentId, enabled];
}
class RefreshAgentStatuses extends TelemetryEvent {}
