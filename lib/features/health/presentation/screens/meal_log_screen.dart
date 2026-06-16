import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kero_space/core/app_theme.dart';
import 'package:intl/intl.dart';

class MealLogScreen extends StatefulWidget {
  final Ingredient ingredient;
  const MealLogScreen({super.key, required this.ingredient});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  double grams = 100.0;
  late final TextEditingController _gramsController;
  DateTime _selectedTime = DateTime.now();
  MealType _selectedMealType = MealType.snack;

  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(text: '100');
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double ratio = grams / 100.0;
    double totalCalories = widget.ingredient.calories * ratio;
    double totalProtein = widget.ingredient.protein * ratio;
    double totalCarbs = widget.ingredient.carbs * ratio;
    double totalFat = widget.ingredient.fat * ratio;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('Log Meal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Fix overflow by using SingleChildScrollView inside an Expanded column layout
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.accentMint.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          size: 48,
                          color: AppTheme.accentMint,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.ingredient.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${totalCalories.toStringAsFixed(0)} kcal',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.accentMint,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Grams Input Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bgElevated,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Amount',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              controller: _gramsController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                suffixText: 'g',
                                suffixStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  grams = double.tryParse(val) ?? 0.0;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Macros Breakdown
                    Row(
                      children: [
                        _buildMacroCard(
                          'Protein',
                          totalProtein,
                          AppTheme.accentCyan,
                        ),
                        const SizedBox(width: 12),
                        _buildMacroCard(
                          'Carbs',
                          totalCarbs,
                          AppTheme.accentRose,
                        ),
                        const SizedBox(width: 12),
                        _buildMacroCard('Fat', totalFat, AppTheme.accentGold),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Meal Settings (Time & Type)
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(
                                  _selectedTime,
                                ),
                              );
                              if (time != null) {
                                setState(() {
                                  _selectedTime = DateTime(
                                    _selectedTime.year,
                                    _selectedTime.month,
                                    _selectedTime.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.bgElevated,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Time',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat.jm().format(_selectedTime),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.bgElevated,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Type',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<MealType>(
                                    value: _selectedMealType,
                                    isExpanded: true,
                                    dropdownColor: AppTheme.bgElevated,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down,
                                      color: AppTheme.textSecondary,
                                    ),
                                    items: MealType.values
                                        .map(
                                          (type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(
                                              type.name.toUpperCase(),
                                              style: const TextStyle(
                                                color: AppTheme.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() => _selectedMealType = val);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Bottom Action Button
            Container(
              padding: const EdgeInsets.all(30),
              child: ElevatedButton(
                onPressed: () => _saveMeal(
                  ratio,
                  totalCalories,
                  totalProtein,
                  totalCarbs,
                  totalFat,
                  _selectedTime,
                  _selectedMealType,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentMint,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Add to Diary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${value.toStringAsFixed(1)}g',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMeal(
    double ratio,
    double cals,
    double pro,
    double carbs,
    double fat,
    DateTime time,
    MealType type,
  ) async {
    final state = context.read<HealthBloc>().state;

    if (state.isFastingMode && !widget.ingredient.isFastingCompliant) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.bgElevated,
          title: const Text(
            'Fasting Breach Warning',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: const Text(
            'This ingredient is not compliant with your fast. Log it anyway?',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Log Anyway',
                style: TextStyle(color: AppTheme.accentRose),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final entry = MealEntry()
      ..deviceId = 'local'
      ..platform = 'Android'
      ..name = widget.ingredient.name
      ..grams = grams
      ..calories = cals
      ..protein = pro
      ..carbs = carbs
      ..fat = fat
      ..fiber = (widget.ingredient.fiber.isNaN ? 0.0 : widget.ingredient.fiber) * ratio
      ..sugar = (widget.ingredient.sugar.isNaN ? 0.0 : widget.ingredient.sugar) * ratio
      ..fastCarbs = (widget.ingredient.fastCarbs.isNaN ? 0.0 : widget.ingredient.fastCarbs) * ratio
      ..slowCarbs = (widget.ingredient.slowCarbs.isNaN ? 0.0 : widget.ingredient.slowCarbs) * ratio
      ..fatSaturated = (widget.ingredient.fatSaturated.isNaN ? 0.0 : widget.ingredient.fatSaturated) * ratio
      ..fatUnsaturated = (widget.ingredient.fatUnsaturated.isNaN ? 0.0 : widget.ingredient.fatUnsaturated) * ratio
      ..cholesterol = (widget.ingredient.cholesterol.isNaN ? 0.0 : widget.ingredient.cholesterol) * ratio
      ..sodium = (widget.ingredient.sodium.isNaN ? 0.0 : widget.ingredient.sodium) * ratio
      ..glycemicIndex = widget.ingredient.glycemicIndex.isNaN ? 0.0 : widget.ingredient.glycemicIndex
      ..timestamp = time
      ..mealType = type;

    if (mounted) {
      context.read<HealthBloc>().add(LogMeal(entry));
      context.pop(); // Pop log screen
      context.pop(); // Pop search screen to return to dashboard
    }
  }
}
