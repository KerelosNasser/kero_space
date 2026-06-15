import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:isar/isar.dart';
import '../../data/repositories/screen_event_repository.dart';
import '../../data/repositories/app_usage_repository.dart';
import '../../data/repositories/click_log_repository.dart';
import '../../data/repositories/blacklist_repository.dart';
import '../../data/models/blacklist_rule.dart';
import '../../data/models/blocker_stat.dart';
import '../../data/models/telemetry_collections.dart';
import '../../../../core/data/kero_space_platform_service.dart';
import '../../../../core/data/isar_service.dart';
import 'telemetry_event.dart' as bloc_event;
import 'telemetry_state.dart';

class TelemetryBloc extends Bloc<bloc_event.TelemetryEvent, TelemetryState> {
  final ScreenEventRepository _screenRepo;
  final AppUsageRepository _usageRepo;
  final ClickLogRepository _clickRepo;
  final BlacklistRepository _blacklistRepo;
  final KeroSpacePlatformService _platform;
  StreamSubscription<void>? _screenSub;
  StreamSubscription<void>? _usageSub;
  Timer? _screenDebounce;
  Timer? _usageDebounce;

  TelemetryBloc(this._screenRepo, this._usageRepo, this._clickRepo,
      this._blacklistRepo, this._platform)
      : super(const TelemetryState()) {
    on<bloc_event.LoadTelemetryDashboard>(_onLoadDashboard);
    on<bloc_event.LoadUnlockHeatmap>(_onLoadHeatmap);
    on<bloc_event.LoadBlockerStats>(_onLoadBlockerStats);
    on<bloc_event.LoadClickLogs>(_onLoadClickLogs);
    on<bloc_event.LoadBlacklist>(_onLoadBlacklist);
    on<bloc_event.AddBlacklistRule>(_onAddRule);
    on<bloc_event.RemoveBlacklistRule>(_onRemoveRule);
    on<bloc_event.UpdateBlacklistRule>(_onUpdateRule);
    on<bloc_event.ToggleAgent>(_onToggleAgent);
    on<bloc_event.RefreshAgentStatuses>(_onRefreshStatuses);

    _screenSub = _screenRepo.watchChanges().listen((_) {
      _screenDebounce?.cancel();
      _screenDebounce = Timer(const Duration(milliseconds: 500), () {
        add(const bloc_event.LoadTelemetryDashboard());
      });
    });
    _usageSub = _usageRepo.watchChanges().listen((_) {
      _usageDebounce?.cancel();
      _usageDebounce = Timer(const Duration(milliseconds: 500), () {
        add(const bloc_event.LoadTelemetryDashboard());
      });
    });

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
      bloc_event.LoadTelemetryDashboard event, Emitter<TelemetryState> emit) async {
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
        clearError: true,
        todayScreenTimeMs: screenTimeMs,
        todayTopApps: topApps,
        weeklyScreenTime: weekly,
        blacklistRules: rules,
        agentStatuses: statuses,
      ));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to load telemetry data.'));
    }
  }

  Future<void> _onLoadHeatmap(
      bloc_event.LoadUnlockHeatmap event, Emitter<TelemetryState> emit) async {
    try {
      final heatmap = await _screenRepo.getUnlockHeatmap(weekStart: event.weekStart);
      emit(state.copyWith(unlockHeatmap: heatmap));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to load heatmap.'));
    }
  }

  Future<void> _onLoadBlockerStats(
      bloc_event.LoadBlockerStats event, Emitter<TelemetryState> emit) async {
    try {
      final isar = IsarService.instance;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final blockerEvents = await isar.telemetryEvents
          .filter()
          .nameEqualTo('blocker_decision')
          .and()
          .timestampGreaterThan(startOfDay)
          .findAll();

      final rules = await _blacklistRepo.getRules();
      final stats = <BlockerStat>[];

      for (final rule in rules) {
        final packageEvents = blockerEvents
            .where((e) => e.dataJson.contains(rule.packageName))
            .toList();
        final blocked = packageEvents.where((e) => e.dataJson.contains('"outcome":"blocked"')).length;
        final granted = packageEvents.where((e) => e.dataJson.contains('"outcome":"granted"')).length;

        stats.add(BlockerStat(
          packageName: rule.packageName,
          blockedAttempts: blocked,
          grantedOverrides: granted,
          date: now,
        ));
      }

      emit(state.copyWith(blockerStats: stats));
    } catch (e) {
      emit(state.copyWith(blockerStats: const []));
    }
  }

  Future<void> _onLoadClickLogs(
      bloc_event.LoadClickLogs event, Emitter<TelemetryState> emit) async {
    try {
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
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to load click logs.'));
    }
  }

  Future<void> _onLoadBlacklist(
      bloc_event.LoadBlacklist event, Emitter<TelemetryState> emit) async {
    try {
      final rules = await _blacklistRepo.getRules();
      emit(state.copyWith(blacklistRules: rules));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to load blacklist.'));
    }
  }

  Future<void> _onAddRule(bloc_event.AddBlacklistRule event, Emitter<TelemetryState> emit) async {
    try {
      await _blacklistRepo.addRule(event.rule);
      final rules = await _blacklistRepo.getRules();
      await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
      emit(state.copyWith(blacklistRules: rules));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to add rule.'));
    }
  }

  Future<void> _onRemoveRule(
      bloc_event.RemoveBlacklistRule event, Emitter<TelemetryState> emit) async {
    try {
      await _blacklistRepo.removeRule(event.packageName);
      final rules = await _blacklistRepo.getRules();
      await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
      emit(state.copyWith(blacklistRules: rules));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to remove rule.'));
    }
  }

  Future<void> _onUpdateRule(
      bloc_event.UpdateBlacklistRule event, Emitter<TelemetryState> emit) async {
    try {
      await _blacklistRepo.updateRule(event.rule);
      final rules = await _blacklistRepo.getRules();
      await _platform.setBlacklistRules(BlacklistRule.listToJson(rules));
      emit(state.copyWith(blacklistRules: rules));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to update rule.'));
    }
  }

  Future<void> _onToggleAgent(bloc_event.ToggleAgent event, Emitter<TelemetryState> emit) async {
    try {
      await _platform.toggleAgent(event.agentId, event.enabled);
      final statuses = await _platform.getAgentStatuses();
      emit(state.copyWith(agentStatuses: statuses));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to toggle agent.'));
    }
  }

  Future<void> _onRefreshStatuses(
      bloc_event.RefreshAgentStatuses event, Emitter<TelemetryState> emit) async {
    try {
      final statuses = await _platform.getAgentStatuses();
      emit(state.copyWith(agentStatuses: statuses));
    } catch (e) {
      emit(state.copyWith(status: TelemetryStatus.failure, errorMessage: 'Failed to refresh statuses.'));
    }
  }

  @override
  Future<void> close() {
    _screenSub?.cancel();
    _usageSub?.cancel();
    _screenDebounce?.cancel();
    _usageDebounce?.cancel();
    return super.close();
  }
}
