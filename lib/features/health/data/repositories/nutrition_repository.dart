import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:kero_space/core/data/isar_service.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class NutritionRepository {
  Future<void> seedIngredientsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final isSeeded = prefs.getBool('ingredients_seeded') ?? false;

    if (isSeeded) return;

    final isar = IsarService.instance;

    try {
      final jsonString = await rootBundle.loadString('assets/ingredients_seed.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      List<Ingredient> ingredients = jsonList.map((json) {
        return Ingredient()
          ..deviceId = 'local'
          ..platform = 'seed'
          ..name = json['name']
          ..calories = (json['calories'] as num).toDouble()
          ..protein = (json['protein'] as num).toDouble()
          ..carbs = (json['carbs'] as num).toDouble()
          ..fat = (json['fat'] as num).toDouble()
          ..isFastingCompliant = json['isFastingCompliant'] ?? false;
      }).toList();

      await isar.writeTxn(() async {
        await isar.ingredients.putAll(ingredients);
      });

      await prefs.setBool('ingredients_seeded', true);
    } catch (e) {
      debugPrint('Error seeding ingredients: $e');
    }
  }

  Future<List<Ingredient>> searchIngredients(String query) async {
    final isar = IsarService.instance;

    if (query.isEmpty) {
      return await isar.ingredients.where().limit(20).findAll();
    }

    return await isar.ingredients
        .filter()
        .nameContains(query, caseSensitive: false)
        .limit(20)
        .findAll();
  }

  Future<void> addCustomIngredient(Ingredient ingredient) async {
    final isar = IsarService.instance;

    await isar.writeTxn(() async {
      await isar.ingredients.put(ingredient);
    });
  }

  Future<void> logMeal(MealEntry entry) async {
    final isar = IsarService.instance;

    await isar.writeTxn(() async {
      await isar.mealEntrys.put(entry);
    });
  }

  Future<List<MealEntry>> getDailyMeals(DateTime day) async {
    final isar = IsarService.instance;

    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return await isar.mealEntrys
        .filter()
        .timestampBetween(startOfDay, endOfDay)
        .findAll();
  }

  Future<List<MealEntry>> getMealsInRange(DateTime start, DateTime end) async {
    final isar = IsarService.instance;
    return await isar.mealEntrys
        .filter()
        .timestampBetween(start, end)
        .findAll();
  }

  Future<UserProfile?> getUserProfile() async {
    final isar = IsarService.instance;
    // Assuming there's only one user profile for the local device
    return await isar.userProfiles.where().findFirst();
  }
}
