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
  final ValueNotifier<String> _queryNotifier = ValueNotifier('');
  final ValueNotifier<CommandCategory> _categoryNotifier = ValueNotifier(CommandCategory.all);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery ?? '';
    _queryNotifier.value = initial;
    _searchController = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inputFocusNode.dispose();
    _queryNotifier.dispose();
    _categoryNotifier.dispose();
    super.dispose();
  }

  void _onCategorySelected(CommandCategory category) {
    HapticFeedback.selectionClick();
    _categoryNotifier.value = category;
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
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
                    child: ValueListenableBuilder<String>(
                      valueListenable: _queryNotifier,
                      builder: (context, query, _) {
                        return TextField(
                          controller: _searchController,
                          focusNode: _inputFocusNode,
                          autofocus: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(fontSize: 15, color: colors.textPrimary),
                          onChanged: (val) => _queryNotifier.value = val,
                          decoration: InputDecoration(
                            hintText: 'Search commands, ask AI, or web...',
                            prefixIcon: Icon(Icons.search_rounded, color: colors.accentPrimary),
                            suffixIcon: query.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      _searchController.clear();
                                      _queryNotifier.value = '';
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
                        );
                      },
                    ),
                  ),

                  // Category Filter Chips
                  SizedBox(
                    height: 36,
                    child: ValueListenableBuilder<CommandCategory>(
                      valueListenable: _categoryNotifier,
                      builder: (context, selectedCategory, _) {
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: CommandCategory.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, idx) {
                            final cat = CommandCategory.values[idx];
                            final isSelected = cat == selectedCategory;
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
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Divider(height: 1),

                  // Content List - Isolated via RepaintBoundary & ValueListenable
                  Expanded(
                    child: RepaintBoundary(
                      child: ValueListenableBuilder<CommandCategory>(
                        valueListenable: _categoryNotifier,
                        builder: (context, category, _) {
                          return ValueListenableBuilder<String>(
                            valueListenable: _queryNotifier,
                            builder: (context, query, _) {
                              final localResults = CommandRegistry.search(
                                query: query,
                                selectedCategory: category,
                              );

                              final predictedCards = query.trim().isNotEmpty &&
                                      (category == CommandCategory.all || category == CommandCategory.aiWeb)
                                  ? IntentPredictionEngine.predict(
                                      context,
                                      query,
                                      onDismissPalette: () => Navigator.of(context).pop(),
                                    )
                                  : <PredictedCard>[];

                              if (localResults.isEmpty && predictedCards.isEmpty) {
                                return _buildEmptyState(context, colors, query);
                              }

                              final hasPredictions = predictedCards.isNotEmpty;
                              final hasLocal = localResults.isNotEmpty;

                              final totalCount = (hasPredictions ? predictedCards.length + 1 : 0) +
                                  (hasLocal ? localResults.length + 1 : 0);

                              return ListView.builder(
                                controller: scrollController,
                                padding: const EdgeInsets.only(top: 8, bottom: 24),
                                itemCount: totalCount,
                                itemBuilder: (context, index) {
                                  // Section 1: Predictions
                                  if (hasPredictions) {
                                    if (index == 0) {
                                      return Padding(
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
                                      );
                                    } else if (index <= predictedCards.length) {
                                      return _buildPredictedTile(context, predictedCards[index - 1], colors);
                                    }
                                  }

                                  // Section 2: Local results
                                  final localOffset = hasPredictions ? predictedCards.length + 1 : 0;
                                  final localIndex = index - localOffset;

                                  if (localIndex == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                                      child: Text(
                                        category == CommandCategory.all
                                            ? 'COMMANDS & ACTIONS'
                                            : category.label.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.1,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    );
                                  }

                                  return _buildCommandTile(context, localResults[localIndex - 1], colors);
                                },
                              );
                            },
                          );
                        },
                      ),
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

  Widget _buildEmptyState(BuildContext context, AppThemeColors colors, String query) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 40, color: colors.textDisabled),
            const SizedBox(height: 12),
            Text(
              'No local commands matching "$query"',
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
                    openWebSearch(query);
                  },
                  icon: const Icon(Icons.travel_explore_rounded, size: 16),
                  label: const Text('Search Web'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop();
                    AiQuickAnswerSheet.show(context, prompt: query);
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
