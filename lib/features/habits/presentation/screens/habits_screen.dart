import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/core/app_theme.dart';
import '../../data/models/habit_model.dart';
import '../cubit/habit_cubit.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  HabitCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocBuilder<HabitCubit, HabitState>(
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            backgroundColor: colors.bgBase,
            body: Center(
              child: CircularProgressIndicator(color: colors.domainProductivity),
            ),
          );
        }

        final filteredHabits = _selectedCategory == null
            ? state.habits
            : state.habits.where((h) => h.category == _selectedCategory).toList();

        final percent = (state.completionRate * 100).round();

        final bottomInset = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          backgroundColor: colors.bgBase,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Habit Tracker',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: colors.textPrimary,
              ),
            ),
            iconTheme: IconThemeData(color: colors.textPrimary),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () => _showAddHabitSheet(context),
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            bottom: true,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: bottomInset + 32,
                  ),
                  children: [
                    // Pro Detox & Progress Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colors.domainProductivity.withValues(alpha: 0.2),
                            colors.accentPrimary.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.domainProductivity.withValues(alpha: 0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.spa_rounded, color: colors.domainProductivity, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DIGITAL DETOX & ATOMIC HABITS',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.1,
                                      color: colors.domainProductivity,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$percent% Done',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: state.completionRate,
                              backgroundColor: colors.borderSubtle,
                              valueColor: AlwaysStoppedAnimation<Color>(colors.domainProductivity),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${state.completedTodayCount} of ${state.totalHabitsCount} habits completed today. Keep your dopamine clean!',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildCategoryChip('All', null, colors),
                          const SizedBox(width: 8),
                          _buildCategoryChip('📵 Phone Detox', HabitCategory.detox, colors),
                          const SizedBox(width: 8),
                          _buildCategoryChip('💧 Health', HabitCategory.health, colors),
                          const SizedBox(width: 8),
                          _buildCategoryChip('📖 Mind', HabitCategory.mind, colors),
                          const SizedBox(width: 8),
                          _buildCategoryChip('🎯 Focus', HabitCategory.focus, colors),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Habits List
                    if (filteredHabits.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Center(
                          child: Text(
                            'No habits in this category yet.',
                            style: TextStyle(color: colors.textSecondary, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ...filteredHabits.map((habit) => _buildHabitCard(context, habit, colors)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String label, HabitCategory? category, AppThemeColors colors) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = category),
      backgroundColor: colors.bgSurface,
      selectedColor: colors.domainProductivity.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? colors.domainProductivity : colors.textPrimary,
      ),
      side: BorderSide(
        color: isSelected ? colors.domainProductivity : colors.borderSubtle,
      ),
    );
  }

  Widget _buildHabitCard(BuildContext context, Habit habit, AppThemeColors colors) {
    final isDone = habit.isCompletedToday;
    final habitColor = Color(habit.colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? habitColor.withValues(alpha: 0.5) : colors.borderSubtle,
          width: isDone ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Check-in button
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  context.read<HabitCubit>().toggleHabit(habit.id);
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? habitColor : Colors.transparent,
                    border: Border.all(
                      color: isDone ? habitColor : colors.textSecondary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                      : null,
                ),
              ),
              const SizedBox(width: 14),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (habit.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        habit.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Streak Flame
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.streakCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colors.accentWarning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 7-Day Mini Matrix (Mon to Sun of current week)
          Row(
            children: List.generate(7, (dayOffset) {
              final today = DateTime.now();
              // Calculate past 6 days + today
              final targetDate = today.subtract(Duration(days: 6 - dayOffset));
              final completed = habit.isCompletedOn(targetDate);
              final isToday = dayOffset == 6;

              final dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final weekdayIndex = targetDate.weekday - 1; // 0..6
              final label = dayLetters[weekdayIndex];

              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? colors.textPrimary : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: completed ? habitColor : colors.bgBase,
                        border: Border.all(
                          color: isToday
                              ? colors.textPrimary.withValues(alpha: 0.8)
                              : colors.borderSubtle,
                          width: isToday ? 1.5 : 1.0,
                        ),
                      ),
                      child: completed
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    final colors = context.appColors;
    final titleController = TextEditingController();
    final descController = TextEditingController();
    HabitCategory category = HabitCategory.detox;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Habit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Habit Title',
                      hintText: 'e.g. 10 pages before opening Instagram',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'e.g. Keep Kindle next to bed',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: HabitCategory.values.map((cat) {
                      final isSelected = category == cat;
                      return ChoiceChip(
                        label: Text(cat.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (_) => setSheetState(() => category = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        final newHabit = Habit(
                          id: 'habit-${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          description: descController.text.trim(),
                          category: category,
                        );

                        context.read<HabitCubit>().addHabit(newHabit);
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Create Habit'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
