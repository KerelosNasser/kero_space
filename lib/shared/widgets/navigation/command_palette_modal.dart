import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/app_theme.dart';
import '../../../../core/navigation/command_registry.dart';
import 'ai_quick_answer_sheet.dart';

class CommandPaletteModal extends StatefulWidget {
  final ValueChanged<int> onSelectBranch;
  final String? initialQuery;

  const CommandPaletteModal({
    super.key,
    required this.onSelectBranch,
    this.initialQuery,
  });

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<int> onSelectBranch,
    String? initialQuery,
  }) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommandPaletteModal(
        onSelectBranch: onSelectBranch,
        initialQuery: initialQuery,
      ),
    );
  }

  @override
  State<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends State<CommandPaletteModal> {
  late final TextEditingController _searchController;
  final FocusNode _inputFocusNode = FocusNode();
  String _query = '';
  CommandCategory _selectedCategory = CommandCategory.all;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _onCategorySelected(CommandCategory category) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedCategory = category;
    });
  }

  void _executeCommand(CommandItem item) {
    HapticFeedback.lightImpact();
    CommandHistoryService.recordCommandExecution(item.id);
    Navigator.of(context).pop();
    item.onExecute(context, onSelectBranch: widget.onSelectBranch);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    final localResults = CommandRegistry.search(
      query: _query,
      selectedCategory: _selectedCategory,
    );

    final predictedCards = _query.trim().isNotEmpty &&
            (_selectedCategory == CommandCategory.all ||
                _selectedCategory == CommandCategory.aiWeb)
        ? IntentPredictionEngine.predict(
            context,
            _query,
            onDismissPalette: () => Navigator.of(context).pop(),
          )
        : <PredictedCard>[];

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutQuad,
      child: DraggableScrollableSheet(
        initialChildSize: 0.82,
        minChildSize: 0.45,
        maxChildSize: 0.94,
        builder: (context, scrollController) {
          return Material(
            color: colors.bgBase,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: colors.borderSubtle, width: 1),
              ),
              child: Column(
              children: [
                // Top drag bar
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _inputFocusNode,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 15, color: colors.textPrimary),
                    onChanged: (val) => setState(() => _query = val),
                    decoration: InputDecoration(
                      hintText: 'Search commands, ask AI, or web...',
                      prefixIcon: Icon(Icons.search_rounded, color: colors.accentPrimary),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                            )
                          : Container(
                              margin: const EdgeInsets.all(10),
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

                // Category Filter Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: CommandCategory.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final cat = CommandCategory.values[idx];
                      final isSelected = cat == _selectedCategory;
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: isSelected,
                        onSelected: (_) => _onCategorySelected(cat),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? (context.isDarkMode ? Colors.black : Colors.white)
                              : colors.textSecondary,
                        ),
                        selectedColor: colors.accentPrimary,
                        backgroundColor: colors.bgSurface,
                        side: BorderSide(
                          color: isSelected ? colors.accentPrimary : colors.borderSubtle,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),

                // Content List
                Expanded(
                  child: (localResults.isEmpty && predictedCards.isEmpty)
                      ? _buildEmptyState(context, colors)
                      : ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.only(top: 8, bottom: 24),
                          children: [
                            // 1. Smart Intent Predictions (AI / Web / URL)
                            if (predictedCards.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.auto_awesome_rounded,
                                        size: 13, color: colors.accentPrimary),
                                    const SizedBox(width: 6),
                                    Text(
                                      'SMART PREDICTIONS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                        color: colors.accentPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...predictedCards.map((card) => _buildPredictedTile(context, card, colors)),
                              const Divider(height: 16),
                            ],

                            // 2. Local Commands & Actions
                            if (localResults.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                                child: Text(
                                  _selectedCategory == CommandCategory.all
                                      ? 'COMMANDS & ACTIONS'
                                      : _selectedCategory.label.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              ...localResults.map((item) => _buildCommandTile(context, item, colors)),
                            ],
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildPredictedTile(BuildContext context, PredictedCard card, AppThemeColors colors) {
    final isAi = card.intent == CommandIntent.aiPrompt;
    final accentColor = isAi ? colors.domainProductivity : colors.domainTelemetry;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: card.onExecute,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accentColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(card.icon, size: 18, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      card.subtitle,
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  card.badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandTile(BuildContext context, CommandItem item, AppThemeColors colors) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colors.borderSubtle),
        ),
        child: Text(
          item.badge,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: colors.textSecondary,
          ),
        ),
      ),
      onTap: () => _executeCommand(item),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppThemeColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: colors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'No local commands matching "$_query"',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Search the web or ask AI assistant directly:',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    openWebSearch(_query);
                  },
                  icon: const Icon(Icons.travel_explore_rounded, size: 16),
                  label: const Text('Search Web'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                    AiQuickAnswerSheet.show(context, prompt: _query);
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('Ask AI'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
