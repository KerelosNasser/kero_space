import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:kero_space/core/navigation/command_registry.dart';
import 'package:kero_space/shared/widgets/navigation/command_palette_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Command System - Intent Prediction Engine Tests', () {
    test('Detects URL intent accurately', () {
      final mockContext = _MockBuildContext();
      final cards = IntentPredictionEngine.predict(
        mockContext,
        'https://flutter.dev',
        onDismissPalette: () {},
      );

      expect(cards.any((c) => c.intent == CommandIntent.directUrl), isTrue);
      expect(cards.first.badge, 'BROWSER');
    });

    test('Detects domain URL without protocol', () {
      final mockContext = _MockBuildContext();
      final cards = IntentPredictionEngine.predict(
        mockContext,
        'github.com/flutter',
        onDismissPalette: () {},
      );

      expect(cards.any((c) => c.intent == CommandIntent.directUrl), isTrue);
    });

    test('Detects AI prompt intent with question mark', () {
      final mockContext = _MockBuildContext();
      final cards = IntentPredictionEngine.predict(
        mockContext,
        'what is coptic computus?',
        onDismissPalette: () {},
      );

      expect(cards.any((c) => c.intent == CommandIntent.aiPrompt), isTrue);
      final aiCard = cards.firstWhere((c) => c.intent == CommandIntent.aiPrompt);
      expect(aiCard.badge, 'AI');
    });

    test('Detects AI prompt intent with prefix', () {
      final mockContext = _MockBuildContext();
      final cards = IntentPredictionEngine.predict(
        mockContext,
        'ai: summarize my productivity backlog',
        onDismissPalette: () {},
      );

      expect(cards.any((c) => c.intent == CommandIntent.aiPrompt), isTrue);
    });

    test('Always provides web search fallback for general queries', () {
      final mockContext = _MockBuildContext();
      final cards = IntentPredictionEngine.predict(
        mockContext,
        'egx30 stock price today',
        onDismissPalette: () {},
      );

      expect(cards.any((c) => c.intent == CommandIntent.webSearch), isTrue);
      final webCard = cards.firstWhere((c) => c.intent == CommandIntent.webSearch);
      expect(webCard.badge, 'WEB');
    });
  });

  group('Command System - Search & Registry Tests', () {
    test('Registry contains all 6 core navigation branches', () {
      final branches = CommandRegistry.items
          .where((i) => i.id.startsWith('branch_'))
          .toList();
      expect(branches.length, 6);
    });

    test('Direct actions include theme switch, fasting, voice, and attendance', () {
      final actions = CommandRegistry.items
          .where((i) => i.category == CommandCategory.action)
          .map((i) => i.id)
          .toList();

      expect(actions.contains('action_toggle_theme_mode'), isTrue);
      expect(actions.contains('action_toggle_fasting'), isTrue);
      expect(actions.contains('action_start_voice'), isTrue);
      expect(actions.contains('action_mark_attendance'), isTrue);
    });

    test('Fuzzy search ranks exact match top', () {
      final results = CommandRegistry.search(query: 'dark');
      expect(results.isNotEmpty, isTrue);
      expect(results.first.id, 'action_toggle_theme_mode');
    });

    test('Category filtering restricts search results', () {
      final navResults = CommandRegistry.search(
        query: '',
        selectedCategory: CommandCategory.navigation,
      );

      expect(navResults.every((i) => i.category == CommandCategory.navigation), isTrue);

      final actionResults = CommandRegistry.search(
        query: '',
        selectedCategory: CommandCategory.action,
      );

      expect(actionResults.every((i) => i.category == CommandCategory.action), isTrue);
    });
  });

  group('Command System - History Service Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Records executed command and preserves MRU order', () async {
      await CommandHistoryService.recordCommandExecution('branch_home');
      await CommandHistoryService.recordCommandExecution('deep_new_note');
      await CommandHistoryService.recordCommandExecution('branch_home');

      final recents = await CommandHistoryService.getRecentCommandIds();
      expect(recents.first, 'branch_home');
      expect(recents[1], 'deep_new_note');
      expect(recents.length, 2);
    });
  });

  group('Command System - Widget Rendering Tests', () {
    testWidgets('CommandPaletteModal renders and filters without exception', (tester) async {
      int selectedBranch = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CommandPaletteModal(
              onSelectBranch: (i) => selectedBranch = i,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('⚡ Actions'), findsOneWidget);
      expect(find.text('🧭 Modules'), findsOneWidget);

      // Enter query
      await tester.enterText(find.byType(TextField), 'health');
      await tester.pumpAndSettle();

      // Tap on item
      await tester.tap(find.text('Health & Nutrition'));
      await tester.pumpAndSettle();

      expect(selectedBranch, 2);
    });

    testWidgets('CommandPaletteModal switches category chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CommandPaletteModal(
              onSelectBranch: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Actions chip
      await tester.tap(find.text('⚡ Actions'));
      await tester.pumpAndSettle();

      expect(find.text('Toggle Dark / Light Mode'), findsOneWidget);
      expect(find.text('Toggle Spiritual Fasting Mode'), findsOneWidget);
    });

    testWidgets('CommandPaletteModal shows AI and Web search prediction cards', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CommandPaletteModal(
              onSelectBranch: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Type question
      await tester.enterText(find.byType(TextField), 'how to configure fasting?');
      await tester.pumpAndSettle();

      expect(find.text('SMART PREDICTIONS'), findsOneWidget);
      expect(find.text('Ask AI: "how to configure fasting?"'), findsOneWidget);
      expect(find.text('Search Web: "how to configure fasting?"'), findsOneWidget);
    });
  });
}

class _MockBuildContext extends Fake implements BuildContext {}
