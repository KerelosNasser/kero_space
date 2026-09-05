import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/core/navigation/navigation_mode.dart';
import 'package:kero_space/core/navigation/navigation_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Systems & Cubit Tests', () {
    test('All 5 AppNavStyle enum values have valid metadata and icons', () {
      expect(AppNavStyle.values.length, 5);

      for (final style in AppNavStyle.values) {
        expect(style.displayName.isNotEmpty, isTrue);
        expect(style.tagline.isNotEmpty, isTrue);
        expect(style.tag.isNotEmpty, isTrue);
        expect(style.icon, isNotNull);
      }
    });

    test('NavigationCubit initializes with default commandCapsule mode', () {
      SharedPreferences.setMockInitialValues({});
      final cubit = NavigationCubit();
      expect(cubit.state.mode, AppNavStyle.commandCapsule);
    });

    test('NavigationCubit transitions between all 5 navigation modes', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = NavigationCubit();

      await cubit.setNavigationMode(AppNavStyle.threePillars);
      expect(cubit.state.mode, AppNavStyle.threePillars);

      await cubit.setNavigationMode(AppNavStyle.floatingIsland);
      expect(cubit.state.mode, AppNavStyle.floatingIsland);

      await cubit.setNavigationMode(AppNavStyle.bentoHub);
      expect(cubit.state.mode, AppNavStyle.bentoHub);

      await cubit.setNavigationMode(AppNavStyle.classicBar);
      expect(cubit.state.mode, AppNavStyle.classicBar);

      await cubit.setNavigationMode(AppNavStyle.commandCapsule);
      expect(cubit.state.mode, AppNavStyle.commandCapsule);
    });
  });
}
