import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:kero_space/features/telemetry/data/repositories/screen_event_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/app_usage_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/click_log_repository.dart';
import 'package:kero_space/features/telemetry/data/repositories/blacklist_repository.dart';
import 'package:kero_space/core/data/kero_space_platform_service.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_bloc.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_event.dart';
import 'package:kero_space/features/telemetry/presentation/bloc/telemetry_state.dart';

@GenerateMocks([
  ScreenEventRepository, AppUsageRepository, ClickLogRepository,
  BlacklistRepository, KeroSpacePlatformService,
])
void main() {
  late MockScreenEventRepository screenRepo;
  late MockAppUsageRepository usageRepo;
  late MockClickLogRepository clickRepo;
  late MockBlacklistRepository blacklistRepo;
  late MockKeroSpacePlatformService platformService;

  setUp(() {
    screenRepo = MockScreenEventRepository();
    usageRepo = MockAppUsageRepository();
    clickRepo = MockClickLogRepository();
    blacklistRepo = MockBlacklistRepository();
    platformService = MockKeroSpacePlatformService();
    when(screenRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
    when(usageRepo.watchChanges()).thenAnswer((_) => const Stream.empty());
  });

  blocTest<TelemetryBloc, TelemetryState>(
    'LoadTelemetryDashboard emits loading then success with todayScreenTimeMs',
    build: () {
      when(screenRepo.getTotalScreenTimeMs(from: anyNamed('from'), to: anyNamed('to')))
          .thenAnswer((_) async => 3600000);
      when(usageRepo.getTodayUsage()).thenAnswer((_) async => []);
      when(usageRepo.getWeeklyScreenTimeTotals()).thenAnswer((_) async => []);
      when(blacklistRepo.getRules()).thenAnswer((_) async => []);
      when(platformService.getAgentStatuses()).thenAnswer((_) async => {});
      return TelemetryBloc(screenRepo, usageRepo, clickRepo, blacklistRepo, platformService);
    },
    act: (bloc) => bloc.add(LoadTelemetryDashboard()),
    expect: () => [
      isA<TelemetryState>().having((s) => s.status, 'status', TelemetryStatus.loading),
      isA<TelemetryState>()
        .having((s) => s.status, 'status', TelemetryStatus.success)
        .having((s) => s.todayScreenTimeMs, 'screenTime', 3600000),
    ],
  );
}
