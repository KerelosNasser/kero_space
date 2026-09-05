import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app_theme.dart';

class CommandActionItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final VoidCallback onExecute;

  const CommandActionItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.onExecute,
  });
}

class CommandPaletteModal extends StatefulWidget {
  final ValueChanged<int> onSelectBranch;

  const CommandPaletteModal({super.key, required this.onSelectBranch});

  static Future<void> show(BuildContext context, {required ValueChanged<int> onSelectBranch}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommandPaletteModal(onSelectBranch: onSelectBranch),
    );
  }

  @override
  State<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends State<CommandPaletteModal> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<CommandActionItem> _buildActions(BuildContext context) {
    return [
      // Branches
      CommandActionItem(
        title: 'Home Dashboard',
        subtitle: 'Daily focus overview & live telemetry snapshots',
        category: 'NAVIGATION',
        icon: Icons.home_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          widget.onSelectBranch(0);
        },
      ),
      CommandActionItem(
        title: 'Tasks & Productivity',
        subtitle: 'Notes, daily checklist & deep work timer',
        category: 'NAVIGATION',
        icon: Icons.task_alt_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          widget.onSelectBranch(1);
        },
      ),
      CommandActionItem(
        title: 'Health & Nutrition',
        subtitle: 'Food logs, step ring & calorie breakdown',
        category: 'NAVIGATION',
        icon: Icons.favorite_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          widget.onSelectBranch(2);
        },
      ),
      CommandActionItem(
        title: 'Finance & Wealth',
        subtitle: 'EGX stock tracker, expenses & subscriptions',
        category: 'NAVIGATION',
        icon: Icons.account_balance_wallet_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          widget.onSelectBranch(3);
        },
      ),
      CommandActionItem(
        title: 'Church & Spiritual',
        subtitle: 'Coptic calendar, mass attendance & prayers',
        category: 'NAVIGATION',
        icon: Icons.church_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          widget.onSelectBranch(4);
        },
      ),
      CommandActionItem(
        title: 'Device Telemetry',
        subtitle: 'Hardware rules, app timers & usage metrics',
        category: 'NAVIGATION',
        icon: Icons.bar_chart_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          widget.onSelectBranch(5);
        },
      ),

      // Quick Deep Actions
      CommandActionItem(
        title: 'New Note',
        subtitle: 'Open markdown & rich text note editor',
        category: 'QUICK ACTIONS',
        icon: Icons.edit_note_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/note_editor');
        },
      ),
      CommandActionItem(
        title: 'Scan Food Barcode',
        subtitle: 'AI camera barcode & ingredient scanner',
        category: 'QUICK ACTIONS',
        icon: Icons.qr_code_scanner_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/health/scan');
        },
      ),
      CommandActionItem(
        title: 'Search Ingredients',
        subtitle: 'Nutritional database search',
        category: 'QUICK ACTIONS',
        icon: Icons.search_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/health/search');
        },
      ),
      CommandActionItem(
        title: 'Confession Log',
        subtitle: 'Encrypted spiritual journal',
        category: 'QUICK ACTIONS',
        icon: Icons.lock_outline_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/church/confessions_log');
        },
      ),
      CommandActionItem(
        title: 'Blacklist Management',
        subtitle: 'Configure blocked background packages',
        category: 'SYSTEM RULES',
        icon: Icons.block_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/telemetry/blacklist');
        },
      ),

      // Settings
      CommandActionItem(
        title: 'Theme & Appearance',
        subtitle: 'Switch between 10 developer themes & studio',
        category: 'PREFERENCES',
        icon: Icons.palette_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/settings/theme');
        },
      ),
      CommandActionItem(
        title: 'Navigation Systems',
        subtitle: 'Choose your preferred app navigation style',
        category: 'PREFERENCES',
        icon: Icons.navigation_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/settings/navigation');
        },
      ),
      CommandActionItem(
        title: 'App Settings',
        subtitle: 'Data backup, docker backend URL & sync',
        category: 'PREFERENCES',
        icon: Icons.settings_rounded,
        onExecute: () {
          Navigator.of(context).pop();
          context.push('/settings');
        },
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allActions = _buildActions(context);
    final filteredActions = _query.isEmpty
        ? allActions
        : allActions
            .where((item) =>
                item.title.toLowerCase().contains(_query.toLowerCase()) ||
                item.subtitle.toLowerCase().contains(_query.toLowerCase()) ||
                item.category.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.bgBase,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: colors.borderSubtle, width: 1.5),
              left: BorderSide(color: colors.borderSubtle, width: 1),
              right: BorderSide(color: colors.borderSubtle, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Top drag bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (val) => setState(() => _query = val),
                  decoration: InputDecoration(
                    hintText: 'Type a command, screen, or route...',
                    prefixIcon: Icon(Icons.search_rounded, color: colors.accentPrimary),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colors.bgElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: colors.borderSubtle),
                            ),
                            child: Text(
                              'ESC',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.textSecondary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),

              // Action List
              Expanded(
                child: filteredActions.isEmpty
                    ? Center(
                        child: Text(
                          'No commands matching "$_query"',
                          style: TextStyle(color: colors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filteredActions.length,
                        itemBuilder: (context, index) {
                          final item = filteredActions[index];
                          final showCategoryHeader = index == 0 ||
                              filteredActions[index - 1].category != item.category;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showCategoryHeader)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                  child: Text(
                                    item.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                      color: colors.accentPrimary,
                                    ),
                                  ),
                                ),
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: colors.bgSurface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colors.borderSubtle),
                                  ),
                                  child: Icon(item.icon, size: 18, color: colors.textPrimary),
                                ),
                                title: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  item.subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                  ),
                                ),
                                trailing: Icon(Icons.arrow_forward_ios_rounded,
                                    size: 14, color: colors.textDisabled),
                                onTap: item.onExecute,
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
