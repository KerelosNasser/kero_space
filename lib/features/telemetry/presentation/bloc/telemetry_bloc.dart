import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../data/repositories/screen_event_repository.dart';
import '../../data/repositories/app_usage_repository.dart';
import '../../data/repositories/click_log_repository.dart';
import '../../data/repositories/blacklist_repository.dart';
import '../../data/models/blacklist_rule.dart';
import '../../../../core/data/kero_space_platform_service.dart';
import 'telemetry_event.dart';
import 'telemetry_state.dart';

class TelemetryBloc extends Bloc<TelemetryEvent, TelemetryState> {
  final ScreenEventRepository _screenRepo;
  final AppUsageRepository _usageRepo;
  final ClickLogRepository _clickRepo;
  final BlacklistRepository _blacklistRepo;
  final KeroSpacePlatformService _platform;
  StreamSubscription<void>? _screenSub;
  StreamSubscription<void>? _usageSub;

  TelemetryBloc(this._screenRepo, this._usageRepo, this._clickRepo,
      this._blacklistRepo, this._platform)
      : super(const TelemetryState()) {
    on<LoadTelemetryDashboard>(_onLoadDashboard);
    on<LoadUnlockHeatmap>(_onLoadHeatmap);
    on<LoadBlockerStats>(_onLoadBlockerStats);
    on<LoadClickLogs>(_onLoadClickLogs);
    on<LoadBlacklist>(_onLoadBlacklist);
    on<AddBlacklistRule>(_onAddRule);
    on<RemoveBlacklistRule>(_onRemoveRule);
    on<UpdateBlacklistRule>(_onUpdateRule);
    on<ToggleAgent>(_onToggleAgent);
    on<RefreshAgentStatuses>(_onRefreshStatuses);

    _screenSub = _screenRepo.watchChanges().listen((_) => add(LoadTelemetryDashboard()));
    _usageSub = _usageRepo.watchChanges().listen((_) => add(LoadTelemetryDashboard()));

    _pruneData();
  }

  Future<void> _pruneData() async {
    try {
      await _screenRepo.pruneOldData();
      await _usageRepo.pruneOldData();
      await _clickRepo.pruneOldData();
    } catch (_) {
      // Silently fail if pruning fails
    }
  }

  Future<void> _onLoadDashboard(
      LoadTelemetryDashboard event, Emitter<TelemetryState> emit) async {
    emit(state.copyWith(status: TelemetryStatus.loading));
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final screenTimeMs = await _screenRepo.getTotalScreenTimeMs(from: startOfDay, to: now);
      final topApps = (await _usageRepo.getTodayUsage()).take(8).toList();
      final weekly = await _usageRepo.getWeeklyScreenTimeTotals();
      final rules = await _blacklistRepo.getRules();
      final statuses = await _platform.getAgentStatuses();
      emit(state.copyWith(
        status: TelemetryStatus.success,
        todayScreenTimeMs: screenTimeMs,
        todayTopApps: topApps,
        weeklyScreenTime: weekly,
        blacklistRules: rules,
        agentStatuses: statuses,
      ));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadHeatmap(
      LoadUnlockHeatmap event, Emitter<TelemetryState> emit) async {
    final heatmap = await _screenRepo.getUnlockHeatmap(weekStart: event.weekStart);
    emit(state.copyWith(unlockHeatmap: heatmap));
  }

  Future<void> _onLoadBlockerStats(
      LoadBlockerStats event, Emitter<TelemetryState> emit) async {
    // Blocker stats aggregate from TelemetryEvent name='blocker_decision'
    // Populated when overlay is shown/dismissed — empty until overlays fire
    emit(state.copyWith(blockerStats: const []));
  }

  Future<void> _onLoadClickLogs(
      LoadClickLogs event, Emitter<TelemetryState> emit) async {
    final logs = await _clickRepo.getClickLogs(
      packageName: event.packageFilter,
      from: event.from,
      to: event.to,
      page: event.page,
    );
    final allLogs = event.page == 0 ? logs : [...state.clickLogs, ...logs];
    emit(state.copyWith(
      clickLogs: allLogs,
      clickLogPage: event.page,
      clickLogHasMore: logs.length == ClickLogRepository.pageSize,
    ));
  }

  Future<void> _onLoadBlacklist(
      LoadBlacklist event, Emitter<TelemetryState> emit) async {
    final rules = await _blacklistRepo.getRules();
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onAddRule(AddBlacklistRule event, Emitter<TelemetryState> emit) async {
    await _blacklistRepo.addRule(event.rule);
    final rules = await _blacklistRepo.getRules();
    await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onRemoveRule(
      RemoveBlacklistRule event, Emitter<TelemetryState> emit) async {
    await _blacklistRepo.removeRule(event.packageName);
    final rules = await _blacklistRepo.getRules();
    await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onUpdateRule(
      UpdateBlacklistRule event, Emitter<TelemetryState> emit) async {
    await _blacklistRepo.updateRule(event.rule);
    final rules = await _blacklistRepo.getRules();
    await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
    emit(state.copyWith(blacklistRules: rules));
  }

  Future<void> _onToggleAgent(ToggleAgent event, Emitter<TelemetryState> emit) async {
    await _platform.toggleAgent(event.agentId, event.enabled);
    final statuses = await _platform.getAgentStatuses();
    emit(state.copyWith(agentStatuses: statuses));
  }

  Future<void> _onRefreshStatuses(
      RefreshAgentStatuses event, Emitter<TelemetryState> emit) async {
    final statuses = await _platform.getAgentStatuses();
    emit(state.copyWith(agentStatuses: statuses));
  }

  @override
  Future<void> close() {
    _screenSub?.cancel();
    _usageSub?.cancel();
    return super.close();
  }
}
