import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:go_router/go_router.dart';

class MealLogScreen extends StatefulWidget {
  final Ingredient ingredient;
  const MealLogScreen({super.key, required this.ingredient});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  double grams = 100.0;

  @override
  Widget build(BuildContext context) {
    double ratio = grams / 100.0;
    double totalCalories = widget.ingredient.calories * ratio;
    double totalProtein = widget.ingredient.protein * ratio;
    double totalCarbs = widget.ingredient.carbs * ratio;
    double totalFat = widget.ingredient.fat * ratio;

    return Scaffold(
      appBar: AppBar(title: const Text('Log Meal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.ingredient.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(labelText: 'Amount (grams)', suffixText: 'g'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '100'),
              onChanged: (val) {
                setState(() {
                  grams = double.tryParse(val) ?? 0.0;
                });
              },
            ),
            const SizedBox(height: 32),
            Text('Calories: ${totalCalories.toStringAsFixed(1)} kcal', style: const TextStyle(fontSize: 18)),
            Text('Protein: ${totalProtein.toStringAsFixed(1)} g', style: const TextStyle(fontSize: 18)),
            Text('Carbs: ${totalCarbs.toStringAsFixed(1)} g', style: const TextStyle(fontSize: 18)),
            Text('Fat: ${totalFat.toStringAsFixed(1)} g', style: const TextStyle(fontSize: 18)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveMeal(totalCalories, totalProtein, totalCarbs, totalFat),
                child: const Text('Save Meal'),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _saveMeal(double cals, double pro, double carbs, double fat) async {
    final state = context.read<HealthBloc>().state;
    
    if (state.isFastingMode && !widget.ingredient.isFastingCompliant) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Fasting Breach Warning'),
          content: const Text('This ingredient contains animal products or is not compliant with the current fast. Do you still want to log it?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true), 
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Log Anyway')
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
      ..timestamp = DateTime.now();

    if (mounted) {
      context.read<HealthBloc>().add(LogMeal(entry));
      context.pop(); // Pop log screen
      context.pop(); // Pop search screen to return to dashboard
    }
  }
}
