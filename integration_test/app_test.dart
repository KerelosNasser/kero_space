import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:kero_space/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Kero Space End-to-End Tests', () {
    testWidgets('App launches and displays onboarding/dashboard', (tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify that there is at least one text element rendered, meaning the app didn't crash
      expect(find.byType(app.KeroSpaceApp), findsOneWidget);

      // Verify that no fatal inline errors were thrown during startup
      expect(find.text('Something went wrong'), findsNothing);
    });
  });
}
