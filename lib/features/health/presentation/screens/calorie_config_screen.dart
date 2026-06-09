import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/presentation/bloc/health_bloc.dart';
import 'package:go_router/go_router.dart';

class CalorieConfigScreen extends StatefulWidget {
  const CalorieConfigScreen({super.key});

  @override
  State<CalorieConfigScreen> createState() => _CalorieConfigScreenState();
}

class _CalorieConfigScreenState extends State<CalorieConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  double height = 175.0;
  double weight = 70.0;
  int age = 25;
  double activityLevel = 1.55; // Moderate

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie Target Configuration')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              initialValue: height.toString(),
              decoration: const InputDecoration(labelText: 'Height (cm)'),
              keyboardType: TextInputType.number,
              onSaved: (val) => height = double.parse(val ?? '0'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: weight.toString(),
              decoration: const InputDecoration(labelText: 'Weight (kg)'),
              keyboardType: TextInputType.number,
              onSaved: (val) => weight = double.parse(val ?? '0'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: age.toString(),
              decoration: const InputDecoration(labelText: 'Age'),
              keyboardType: TextInputType.number,
              onSaved: (val) => age = int.parse(val ?? '0'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<double>(
              initialValue: activityLevel,
              decoration: const InputDecoration(labelText: 'Activity Level'),
              items: const [
                DropdownMenuItem(value: 1.2, child: Text('Sedentary (Little to no exercise)')),
                DropdownMenuItem(value: 1.375, child: Text('Lightly active (Light exercise 1-3 days/week)')),
                DropdownMenuItem(value: 1.55, child: Text('Moderately active (Moderate exercise 3-5 days/week)')),
                DropdownMenuItem(value: 1.725, child: Text('Very active (Hard exercise 6-7 days/week)')),
                DropdownMenuItem(value: 1.9, child: Text('Extra active (Very hard exercise, physical job)')),
              ],
              onChanged: (val) {
                setState(() => activityLevel = val ?? 1.2);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveProfile,
              child: const Text('Calculate BMR & Save'),
            )
          ],
        ),
      ),
    );
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Mifflin-St Jeor Equation (Male default here, can be extended)
      // BMR = 10 * weight(kg) + 6.25 * height(cm) - 5 * age(y) + 5
      double bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      double tdee = bmr * activityLevel;
      
      final profile = UserProfile()
        ..deviceId = 'local'
        ..platform = 'Android'
        ..height = height
        ..weight = weight
        ..age = age
        ..activityLevel = activityLevel
        ..bmrTarget = tdee
        ..timestamp = DateTime.now();

      context.read<HealthBloc>().add(UpdateProfile(profile));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile saved! Daily Target: ${tdee.toInt()} kcal')));
      context.pop();
    }
  }
}
