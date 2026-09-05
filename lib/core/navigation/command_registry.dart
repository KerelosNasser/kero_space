import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../di/injection.dart';
import '../theme/theme_cubit.dart';
import '../../features/health/presentation/bloc/health_bloc.dart';
import '../../features/voice/presentation/bloc/voice_bloc.dart';
import '../../features/voice/presentation/bloc/voice_event.dart';
import '../../features/church/presentation/bloc/church_bloc.dart';
import '../../features/church/data/models/mass_attendance.dart';
import '../../shared/widgets/navigation/ai_quick_answer_sheet.dart';

enum CommandCategory {
  all,
  action,
  navigation,
  aiWeb,
  settings,
}

extension CommandCategoryDetails on CommandCategory {
  String get label {
    switch (this) {
      case CommandCategory.all:
        return 'All';
      case CommandCategory.action:
        return '⚡ Actions';
      case CommandCategory.navigation:
        return '🧭 Modules';
      case CommandCategory.aiWeb:
        return '✨ AI & Web';
      case CommandCategory.settings:
        return '⚙️ Settings';
    }
  }
}

enum CommandIntent {
  localCommand,
  aiPrompt,
  webSearch,
  directUrl,
}

class CommandItem {
  final String id;
  final String title;
  final String subtitle;
  final CommandCategory category;
  final IconData icon;
  final String badge;
  final String titleLower;
  final List<String> keywords;
  final String normalizedTokens;
  final void Function(BuildContext context, {required ValueChanged<int> onSelectBranch}) onExecute;

  CommandItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.badge,
    required this.keywords,
    required this.onExecute,
  })  : titleLower = title.toLowerCase(),
        normalizedTokens = '${title.toLowerCase()} ${subtitle.toLowerCase()} ${keywords.join(' ').toLowerCase()}';
}

class PredictedCard {
  final CommandIntent intent;
  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final VoidCallback onExecute;

  const PredictedCard({
    required this.intent,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.onExecute,
  });
}

class IntentPredictionEngine {
  static final RegExp _urlRegex = RegExp(
    r'^(https?:\/\/)?([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}(:\d+)?(\/.*)?$',
    caseSensitive: false,
  );

  static final List<String> _aiPrefixes = [
    'ai:',
    'ask:',
    'how',
    'why',
    'what',
    'explain',
    'plan',
    'write',
    'suggest',
    'generate',
    'tell',
    'can',
    'is',
    'give',
  ];

  static List<PredictedCard> predict(
    BuildContext context,
    String rawQuery, {
    required VoidCallback onDismissPalette,
  }) {
    final query = rawQuery.trim();
    if (query.isEmpty) return const [];

    final cards = <PredictedCard>[];
    final lower = query.toLowerCase();

    // 1. Direct URL Intent
    if (_urlRegex.hasMatch(query) || lower.startsWith('http://') || lower.startsWith('https://')) {
      cards.add(
        PredictedCard(
          intent: CommandIntent.directUrl,
          title: 'Open URL in Browser',
          subtitle: query,
          icon: Icons.open_in_browser_rounded,
          badge: 'BROWSER',
          onExecute: () {
            HapticFeedback.lightImpact();
            onDismissPalette();
            openDirectUrl(query);
          },
        ),
      );
    }

    // 2. AI Assistant Prompt Intent
    final isExplicitAi = lower.startsWith('ai:') || lower.startsWith('ask:');
    final isNaturalQuestion = query.endsWith('?') ||
        _aiPrefixes.any((p) => lower.startsWith(p) || lower.startsWith('$p '));

    if (isExplicitAi || isNaturalQuestion || query.split(' ').length >= 3) {
      final promptText = isExplicitAi
          ? query.replaceFirst(RegExp(r'^(ai|ask):\s*', caseSensitive: false), '')
          : query;

      cards.add(
        PredictedCard(
          intent: CommandIntent.aiPrompt,
          title: 'Ask AI: "$promptText"',
          subtitle: 'Synthesize answer with Trobio Assistant',
          icon: Icons.auto_awesome_rounded,
          badge: 'AI',
          onExecute: () {
            HapticFeedback.mediumImpact();
            onDismissPalette();
            AiQuickAnswerSheet.show(context, prompt: promptText);
          },
        ),
      );
    }

    // 3. Web Search in Default Android/OS Browser
    cards.add(
      PredictedCard(
        intent: CommandIntent.webSearch,
        title: 'Search Web: "$query"',
        subtitle: 'Search Google in default browser',
        icon: Icons.travel_explore_rounded,
        badge: 'WEB',
        onExecute: () {
          HapticFeedback.lightImpact();
          onDismissPalette();
          openWebSearch(query);
        },
      ),
    );

    return cards;
  }
}

Future<void> openWebSearch(String query) async {
  final encoded = Uri.encodeComponent(query.trim());
  final url = Uri.parse('https://www.google.com/search?q=$encoded');
  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    debugPrint('Failed to open web search: $e');
  }
}

Future<void> openDirectUrl(String url) async {
  var target = url.trim();
  if (!target.startsWith('http://') && !target.startsWith('https://')) {
    target = 'https://$target';
  }
  final uri = Uri.tryParse(target);
  if (uri != null) {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open URL: $e');
    }
  }
}

class CommandHistoryService {
  static const String _prefKey = 'kero_recent_commands';

  static Future<List<String>> getRecentCommandIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefKey) ?? [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> recordCommandExecution(String commandId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_prefKey) ?? [];
      current.remove(commandId);
      current.insert(0, commandId);
      if (current.length > 5) {
        current.removeRange(5, current.length);
      }
      await prefs.setStringList(_prefKey, current);
    } catch (_) {}
  }
}

class CommandRegistry {
  static final List<CommandItem> items = [
    // --- 6 Core Branches ---
    CommandItem(
      id: 'branch_home',
      title: 'Home Dashboard',
      subtitle: 'Daily focus overview & live telemetry snapshots',
      category: CommandCategory.navigation,
      icon: Icons.home_rounded,
      badge: 'MODULE',
      keywords: ['dashboard', 'focus', 'today', 'glance', 'main'],
      onExecute: (ctx, {required onSelectBranch}) => onSelectBranch(0),
    ),
    CommandItem(
      id: 'branch_tasks',
      title: 'Tasks & Productivity',
      subtitle: 'Markdown notes, daily checklist & backlog tree',
      category: CommandCategory.navigation,
      icon: Icons.task_alt_rounded,
      badge: 'MODULE',
      keywords: ['productivity', 'notes', 'todo', 'checklist', 'projects'],
      onExecute: (ctx, {required onSelectBranch}) => onSelectBranch(1),
    ),
    CommandItem(
      id: 'branch_health',
      title: 'Health & Nutrition',
      subtitle: 'Step ring, food logs & macro nutrient breakdown',
      category: CommandCategory.navigation,
      icon: Icons.favorite_rounded,
      badge: 'MODULE',
      keywords: ['steps', 'calories', 'food', 'macros', 'fasting', 'vitals'],
      onExecute: (ctx, {required onSelectBranch}) => onSelectBranch(2),
    ),
    CommandItem(
      id: 'branch_finance',
      title: 'Finance & Wealth',
      subtitle: 'EGX stock tracker, expenses, budgets & subscriptions',
      category: CommandCategory.navigation,
      icon: Icons.account_balance_wallet_rounded,
      badge: 'MODULE',
      keywords: ['money', 'egx', 'stocks', 'income', 'budget', 'holdings'],
      onExecute: (ctx, {required onSelectBranch}) => onSelectBranch(3),
    ),
    CommandItem(
      id: 'branch_church',
      title: 'Church & Spiritual',
      subtitle: 'Coptic calendar, mass streaks & spiritual confessions',
      category: CommandCategory.navigation,
      icon: Icons.church_rounded,
      badge: 'MODULE',
      keywords: ['coptic', 'liturgy', 'mass', 'prayers', 'fasting', 'streak'],
      onExecute: (ctx, {required onSelectBranch}) => onSelectBranch(4),
    ),
    CommandItem(
      id: 'branch_telemetry',
      title: 'Device Telemetry',
      subtitle: 'Screen time, app blacklist & process monitor',
      category: CommandCategory.navigation,
      icon: Icons.bar_chart_rounded,
      badge: 'MODULE',
      keywords: ['screen time', 'monitor', 'hardware', 'rules', 'limits', 'apps'],
      onExecute: (ctx, {required onSelectBranch}) => onSelectBranch(5),
    ),

    // --- In-Place Direct Actions ---
    CommandItem(
      id: 'action_toggle_theme_mode',
      title: 'Toggle Dark / Light Mode',
      subtitle: 'Instant switch between dark and light palette',
      category: CommandCategory.action,
      icon: Icons.brightness_medium_rounded,
      badge: 'SWITCH',
      keywords: ['dark mode', 'light mode', 'theme switch', 'appearance', 'invert'],
      onExecute: (ctx, {required onSelectBranch}) {
        getIt<ThemeCubit>().toggleThemeMode();
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Theme mode switched'),
            duration: Duration(seconds: 1),
          ),
        );
      },
    ),
    CommandItem(
      id: 'action_toggle_fasting',
      title: 'Toggle Spiritual Fasting Mode',
      subtitle: 'Switch fasting dietary filter in health tracker',
      category: CommandCategory.action,
      icon: Icons.restaurant_menu_rounded,
      badge: 'SWITCH',
      keywords: ['fasting', 'lent', 'coptic fast', 'vegan', 'diet'],
      onExecute: (ctx, {required onSelectBranch}) {
        final healthBloc = getIt<HealthBloc>();
        final isFasting = healthBloc.state.isFastingMode;
        healthBloc.add(ToggleFastingMode(!isFasting));
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text(!isFasting ? 'Fasting mode activated' : 'Fasting mode deactivated'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    ),
    CommandItem(
      id: 'action_start_voice',
      title: 'Voice Assistant Assistant',
      subtitle: 'Trigger voice wake command listener',
      category: CommandCategory.action,
      icon: Icons.mic_rounded,
      badge: 'VOICE',
      keywords: ['voice', 'speech', 'listen', 'audio', 'assistant', 'speak'],
      onExecute: (ctx, {required onSelectBranch}) {
        HapticFeedback.mediumImpact();
        getIt<VoiceBloc>().add(StartListeningEvent());
      },
    ),
    CommandItem(
      id: 'action_mark_attendance',
      title: 'Mark Liturgy Attendance Today',
      subtitle: 'Increment Sunday mass streak for today',
      category: CommandCategory.action,
      icon: Icons.check_circle_rounded,
      badge: 'LOG',
      keywords: ['church', 'liturgy', 'mass', 'attend', 'streak', 'today'],
      onExecute: (ctx, {required onSelectBranch}) {
        HapticFeedback.mediumImpact();
        getIt<ChurchBloc>().add(MarkAttendanceEvent(DateTime.now(), ServiceType.liturgy));
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Liturgy attendance logged for today!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    ),

    // --- Deep Routes ---
    CommandItem(
      id: 'deep_new_note',
      title: 'New Note',
      subtitle: 'Open rich markdown & task editor',
      category: CommandCategory.action,
      icon: Icons.edit_note_rounded,
      badge: 'OPEN',
      keywords: ['create note', 'write', 'journal', 'document', 'memo'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/note_editor'),
    ),
    CommandItem(
      id: 'deep_scan_barcode',
      title: 'Scan Food Barcode',
      subtitle: 'AI camera barcode & nutrition scanner',
      category: CommandCategory.action,
      icon: Icons.qr_code_scanner_rounded,
      badge: 'OPEN',
      keywords: ['barcode', 'camera', 'food scan', 'nutrition', 'ingredient'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/health/scan'),
    ),
    CommandItem(
      id: 'deep_search_ingredients',
      title: 'Search Ingredients',
      subtitle: 'Search seed nutrition ingredient database',
      category: CommandCategory.action,
      icon: Icons.search_rounded,
      badge: 'OPEN',
      keywords: ['ingredients', 'recipes', 'database', 'food calories'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/health/search'),
    ),
    CommandItem(
      id: 'deep_confession_log',
      title: 'Encrypted Confession Log',
      subtitle: 'Biometric & AES encrypted spiritual record',
      category: CommandCategory.action,
      icon: Icons.lock_outline_rounded,
      badge: 'OPEN',
      keywords: ['confession', 'secret', 'encrypted', 'spiritual', 'journal'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/church/confessions_log'),
    ),
    CommandItem(
      id: 'deep_blacklist',
      title: 'App Blacklist Management',
      subtitle: 'Block distracted packages and manage rules',
      category: CommandCategory.settings,
      icon: Icons.block_rounded,
      badge: 'RULES',
      keywords: ['block', 'blacklist', 'distraction', 'package', 'rules'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/telemetry/blacklist'),
    ),

    // --- Settings & Customization ---
    CommandItem(
      id: 'settings_theme',
      title: 'Theme & Appearance',
      subtitle: 'Choose from 10 developer themes or customize in Studio',
      category: CommandCategory.settings,
      icon: Icons.palette_rounded,
      badge: 'PALETTE',
      keywords: ['theme', 'appearance', 'palette', 'gruvbox', 'monochrome', 'studio'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/settings/theme'),
    ),
    CommandItem(
      id: 'settings_navigation',
      title: 'Navigation Systems',
      subtitle: 'Switch between 5 smart mobile navigation styles',
      category: CommandCategory.settings,
      icon: Icons.navigation_rounded,
      badge: 'STYLE',
      keywords: ['nav', 'navbar', 'capsule', 'dock', 'bento', 'pillars', 'bottom bar'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/settings/navigation'),
    ),
    CommandItem(
      id: 'settings_general',
      title: 'System Settings',
      subtitle: 'Data backup, workmanager scheduler & sync outbox',
      category: CommandCategory.settings,
      icon: Icons.settings_rounded,
      badge: 'CONFIG',
      keywords: ['settings', 'preferences', 'backup', 'export', 'docker', 'sync'],
      onExecute: (ctx, {required onSelectBranch}) => ctx.push('/settings'),
    ),
  ];

  static final Map<CommandCategory, List<CommandItem>> _categoryPools = {
    CommandCategory.all: items,
    CommandCategory.navigation: items.where((i) => i.category == CommandCategory.navigation).toList(growable: false),
    CommandCategory.action: items.where((i) => i.category == CommandCategory.action).toList(growable: false),
    CommandCategory.aiWeb: items.where((i) => i.category == CommandCategory.aiWeb).toList(growable: false),
    CommandCategory.settings: items.where((i) => i.category == CommandCategory.settings).toList(growable: false),
  };

  static final Map<String, List<CommandItem>> _queryCache = {};

  static List<CommandItem> search({
    required String query,
    CommandCategory selectedCategory = CommandCategory.all,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final pool = _categoryPools[selectedCategory] ?? items;

    if (cleanQuery.isEmpty) {
      return pool;
    }

    final cacheKey = '${selectedCategory.name}_$cleanQuery';
    final cached = _queryCache[cacheKey];
    if (cached != null) return cached;

    // Fast scored ranking algorithm
    final scored = <_ScoredItem>[];

    for (var i = 0; i < pool.length; i++) {
      final item = pool[i];
      final titleLower = item.titleLower;
      int score = 0;

      if (titleLower == cleanQuery) {
        score = 150;
      } else if (titleLower.startsWith(cleanQuery)) {
        score = 100;
      } else if (titleLower.contains(' $cleanQuery')) {
        score = 80;
      } else if (titleLower.contains(cleanQuery)) {
        score = 60;
      } else if (item.keywords.any((k) => k.startsWith(cleanQuery))) {
        score = 45;
      } else if (item.keywords.any((k) => k.contains(cleanQuery))) {
        score = 35;
      } else if (item.normalizedTokens.contains(cleanQuery)) {
        score = 20;
      }

      if (score > 0) {
        scored.add(_ScoredItem(item, score));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));
    final results = List<CommandItem>.generate(scored.length, (i) => scored[i].item, growable: false);

    if (_queryCache.length > 80) {
      _queryCache.clear();
    }
    _queryCache[cacheKey] = results;

    return results;
  }
}

class _ScoredItem {
  final CommandItem item;
  final int score;
  const _ScoredItem(this.item, this.score);
}
