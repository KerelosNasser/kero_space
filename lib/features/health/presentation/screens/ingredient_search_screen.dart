import 'package:flutter/material.dart';
import 'package:kero_space/features/health/data/models/health_collections.dart';
import 'package:kero_space/features/health/data/repositories/nutrition_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:kero_space/core/app_theme.dart';

class IngredientSearchScreen extends StatefulWidget {
  const IngredientSearchScreen({super.key});

  @override
  State<IngredientSearchScreen> createState() => _IngredientSearchScreenState();
}

class _IngredientSearchScreenState extends State<IngredientSearchScreen> {
  final NutritionRepository _repo = GetIt.I<NutritionRepository>();
  List<Ingredient> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  void _search(String query) async {
    setState(() => _isLoading = true);
    final results = await _repo.searchIngredients(query);
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        backgroundColor: AppTheme.bgElevated,
        title: TextField(
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18),
          decoration: const InputDecoration(
            hintText: 'Search food...',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: AppTheme.textSecondary),
          ),
          onChanged: _search,
          autofocus: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: _results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ing = _results[index];
                return GestureDetector(
                  onTap: () => context.push('/health/log', extra: ing),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.bgElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider, width: 1),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Food Icon Container
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: ing.isFastingCompliant 
                                ? AppTheme.accentMint.withValues(alpha: 0.1) 
                                : AppTheme.accentRose.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.restaurant_menu,
                            color: ing.isFastingCompliant ? AppTheme.accentMint : AppTheme.accentRose,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ing.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (ing.isFastingCompliant)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentMint.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Vegan',
                                        style: TextStyle(color: AppTheme.accentMint, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Macros Chips
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildMacroChip('${ing.calories.toInt()} kcal', AppTheme.accentViolet),
                                  _buildMacroChip('${ing.protein}g P', AppTheme.accentRose),
                                  _buildMacroChip('${ing.carbs}g C', AppTheme.accentCyan),
                                  _buildMacroChip('${ing.fat}g F', AppTheme.accentGold),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/health/scan'),
        backgroundColor: AppTheme.accentViolet,
        child: const Icon(Icons.camera_alt, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildMacroChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
