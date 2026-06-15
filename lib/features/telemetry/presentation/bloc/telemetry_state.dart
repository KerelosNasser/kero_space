import 'package:equatable/equatable.dart';
import 'package:kero_space/features/telemetry/data/models/telemetry_collections.dart' as isar_models;
import '../../data/models/blacklist_rule.dart';
import '../../data/models/blocker_stat.dart';

enum TelemetryStatus { initial, loading, success, failure }

class TelemetryState extends Equatable {
  final TelemetryStatus status;
  final String? errorMessage;
  final int todayScreenTimeMs;
  final List<isar_models.AppUsageRecord> todayTopApps;
  final List<(DateTime, int)> weeklyScreenTime;
  final List<List<int>> unlockHeatmap;          // 7×24
  final List<BlockerStat> blockerStats;
  final List<isar_models.TelemetryEvent> clickLogs;
  final int clickLogPage;
  final bool clickLogHasMore;
  final List<BlacklistRule> blacklistRules;
  final Map<String, bool> agentStatuses;

  const TelemetryState({
    this.status = TelemetryStatus.initial,
    this.errorMessage,
    this.todayScreenTimeMs = 0,
    this.todayTopApps = const [],
    this.weeklyScreenTime = const [],
    this.unlockHeatmap = const [],
    this.blockerStats = const [],
    this.clickLogs = const [],
    this.clickLogPage = 0,
    this.clickLogHasMore = true,
    this.blacklistRules = const [],
    this.agentStatuses = const {},
  });

  TelemetryState copyWith({
    TelemetryStatus? status,
    bool clearError = false,
    String? errorMessage,
    int? todayScreenTimeMs,
    List<isar_models.AppUsageRecord>? todayTopApps,
    List<(DateTime, int)>? weeklyScreenTime,
    List<List<int>>? unlockHeatmap,
    List<BlockerStat>? blockerStats,
    List<isar_models.TelemetryEvent>? clickLogs,
    int? clickLogPage,
    bool? clickLogHasMore,
    List<BlacklistRule>? blacklistRules,
    Map<String, bool>? agentStatuses,
  }) => TelemetryState(
    status: status ?? this.status,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    todayScreenTimeMs: todayScreenTimeMs ?? this.todayScreenTimeMs,
    todayTopApps: todayTopApps ?? this.todayTopApps,
    weeklyScreenTime: weeklyScreenTime ?? this.weeklyScreenTime,
    unlockHeatmap: unlockHeatmap ?? this.unlockHeatmap,
    blockerStats: blockerStats ?? this.blockerStats,
    clickLogs: clickLogs ?? this.clickLogs,
    clickLogPage: clickLogPage ?? this.clickLogPage,
    clickLogHasMore: clickLogHasMore ?? this.clickLogHasMore,
    blacklistRules: blacklistRules ?? this.blacklistRules,
    agentStatuses: agentStatuses ?? this.agentStatuses,
  );

  @override
  List<Object?> get props => [
    status, errorMessage, todayScreenTimeMs, todayTopApps,
    weeklyScreenTime, unlockHeatmap, blockerStats, clickLogs,
    clickLogPage, clickLogHasMore, blacklistRules, agentStatuses,
  ];
}
