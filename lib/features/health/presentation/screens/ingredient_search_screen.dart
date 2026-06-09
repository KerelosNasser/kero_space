import 'package:flutter/material.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/data/repositories/nutrition_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class IngredientSearchScreen extends StatefulWidget {
  const IngredientSearchScreen({super.key});

  @override
  State<IngredientSearchScreen> createState() => _IngredientSearchScreenState();
}

class _IngredientSearchScreenState extends State<IngredientSearchScreen> {
  final NutritionRepository _repo = GetIt.I<NutritionRepository>();
  List<Ingredient> _results = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search('');
  }

  void _search(String query) async {
    final results = await _repo.searchIngredients(query);
    if (mounted) {
      setState(() {
        _query = query;
        _results = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search food...',
            border: InputBorder.none,
          ),
          onChanged: _search,
          autofocus: true,
        ),
      ),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final ing = _results[index];
          return ListTile(
            title: Text(ing.name),
            subtitle: Text('${ing.calories} kcal | ${ing.protein}g P | ${ing.carbs}g C | ${ing.fat}g F'),
            trailing: ing.isFastingCompliant ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.warning, color: Colors.orange),
            onTap: () {
              context.push('/health/log', extra: ing);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // In a real app this would open a dialog to create a custom ingredient
          // For now, we mock a quick creation
          final newIng = Ingredient()
            ..deviceId = 'local'
            ..platform = 'Android'
            ..name = 'Custom Food - $_query'
            ..calories = 100
            ..protein = 5
            ..carbs = 10
            ..fat = 2
            ..isFastingCompliant = true;
          _repo.addCustomIngredient(newIng);
          _search(_query);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
