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
  late final List<Widget Function()> _sections;

  @override
  void initState() {
    super.initState();
    _gramsController = TextEditingController(text: '100');
    _sections = [
      _buildHeaderSection,
      _buildAmountSection,
      _buildMacrosSection,
      _buildDetailsSection,
    ];
  }

  @override
  void dispose() {
    _gramsController.dispose();
    super.dispose();
  }

  double get _ratio => grams / 100.0;
  double get _totalCalories => widget.ingredient.calories * _ratio;
  double get _totalProtein => widget.ingredient.protein * _ratio;
  double get _totalCarbs => widget.ingredient.carbs * _ratio;
  double get _totalFat => widget.ingredient.fat * _ratio;

  Widget _buildHeaderSection() {
    final colors = context.appColors;

    return Column(
      children: [
        // Hero Header
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.domainHealth.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.restaurant,
              size: 48,
              color: colors.domainHealth,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.ingredient.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_totalCalories.toStringAsFixed(0)} kcal',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: colors.accentSuccess,
          ),
        ),
      ],
    );
  }

  Widget _buildAmountSection() {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Text(
            'Amount',
            style: TextStyle(fontSize: 16, color: colors.textSecondary),
          ),
          const Spacer(),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _gramsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                suffixText: 'g',
                suffixStyle: TextStyle(
                  fontSize: 16,
                  color: colors.textSecondary,
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
    );
  }

  Widget _buildMacrosSection() {
    final colors = context.appColors;

    return Row(
      children: [
        _buildMacroCard('Protein', _totalProtein, colors.accentDanger),
        const SizedBox(width: 12),
        _buildMacroCard('Carbs', _totalCarbs, colors.accentPrimary),
        const SizedBox(width: 12),
        _buildMacroCard('Fat', _totalFat, colors.accentWarning),
      ],
    );
  }

  Widget _buildDetailsSection() {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
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
                    initialTime: TimeOfDay.fromDateTime(_selectedTime),
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
                    color: colors.bgSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Time',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.jm().format(_selectedTime),
                        style: TextStyle(
                          color: colors.textPrimary,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.bgSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<MealType>(
                        value: _selectedMealType,
                        isExpanded: true,
                        dropdownColor: colors.bgSurface,
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: colors.textSecondary,
                        ),
                        items: MealType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.name.toUpperCase(),
                                  style: TextStyle(
                                    color: colors.textPrimary,
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        title: Text('Log Meal', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : (index == 1 ? 40 : 24),
                    ),
                    child: _sections[index](),
                  );
                },
              ),
            ),
            // Bottom Action Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveMeal(
                  _selectedTime,
                  _selectedMealType,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.domainHealth,
                  foregroundColor: Colors.white,
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
    final colors = context.appColors;
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
              style: TextStyle(
                color: colors.textPrimary,
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
    DateTime time,
    MealType type,
  ) async {
    final state = context.read<HealthBloc>().state;
    final colors = context.appColors;

    if (state.isFastingMode && !widget.ingredient.isFastingCompliant) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: colors.bgSurface,
          title: Text(
            'Fasting Breach Warning',
            style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'This ingredient is not compliant with your fast. Log it anyway?',
            style: TextStyle(color: colors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'Log Anyway',
                style: TextStyle(color: colors.accentError, fontWeight: FontWeight.bold),
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
      ..calories = _totalCalories.isNaN ? 0.0 : _totalCalories
      ..protein = _totalProtein.isNaN ? 0.0 : _totalProtein
      ..carbs = _totalCarbs.isNaN ? 0.0 : _totalCarbs
      ..fat = _totalFat.isNaN ? 0.0 : _totalFat
      ..fiber = (widget.ingredient.fiber.isNaN ? 0.0 : widget.ingredient.fiber) * _ratio
      ..sugar = (widget.ingredient.sugar.isNaN ? 0.0 : widget.ingredient.sugar) * _ratio
      ..fastCarbs = (widget.ingredient.fastCarbs.isNaN ? 0.0 : widget.ingredient.fastCarbs) * _ratio
      ..slowCarbs = (widget.ingredient.slowCarbs.isNaN ? 0.0 : widget.ingredient.slowCarbs) * _ratio
      ..fatSaturated = (widget.ingredient.fatSaturated.isNaN ? 0.0 : widget.ingredient.fatSaturated) * _ratio
      ..fatUnsaturated = (widget.ingredient.fatUnsaturated.isNaN ? 0.0 : widget.ingredient.fatUnsaturated) * _ratio
      ..cholesterol = (widget.ingredient.cholesterol.isNaN ? 0.0 : widget.ingredient.cholesterol) * _ratio
      ..sodium = (widget.ingredient.sodium.isNaN ? 0.0 : widget.ingredient.sodium) * _ratio
      ..glycemicIndex = widget.ingredient.glycemicIndex.isNaN ? 0.0 : widget.ingredient.glycemicIndex
      ..timestamp = time
      ..mealType = type;

    if (mounted) {
      context.read<HealthBloc>().add(LogMeal(entry));
      context.pop(true);
    }
  }
}
