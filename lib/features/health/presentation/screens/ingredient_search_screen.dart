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
    _initSearch();
  }

  Future<void> _initSearch() async {
    await _repo.seedIngredientsIfNeeded();
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
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.bgBase,
      appBar: AppBar(
        backgroundColor: colors.bgSurface,
        elevation: 0,
        title: TextField(
          style: TextStyle(color: colors.textPrimary, fontSize: 18),
          decoration: InputDecoration(
            hintText: 'Search food or ingredients...',
            hintStyle: TextStyle(color: colors.textSecondary),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: colors.textSecondary),
          ),
          onChanged: _search,
          autofocus: true,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colors.accentPrimary))
          : _results.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: colors.domainHealth.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No ingredients found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try searching for another food item or scan your meal.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  itemCount: _results.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ing = _results[index];
                    return GestureDetector(
                      onTap: () async {
                        final logged = await context.push<bool>('/health/log', extra: ing);
                        if (logged == true && context.mounted) {
                          context.pop();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderSubtle, width: 1),
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
                                    ? colors.accentSuccess.withValues(alpha: 0.15) 
                                    : colors.domainHealth.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.restaurant_menu,
                                color: ing.isFastingCompliant ? colors.accentSuccess : colors.domainHealth,
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
                                          style: TextStyle(
                                            color: colors.textPrimary,
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
                                            color: colors.accentSuccess.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Vegan',
                                            style: TextStyle(color: colors.accentSuccess, fontSize: 10, fontWeight: FontWeight.bold),
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
                                      _buildMacroChip('${ing.calories.toInt()} kcal', colors.domainProductivity),
                                      _buildMacroChip('${ing.protein}g P', colors.accentDanger),
                                      _buildMacroChip('${ing.carbs}g C', colors.accentPrimary),
                                      _buildMacroChip('${ing.fat}g F', colors.accentWarning),
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
        backgroundColor: colors.domainHealth,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  Widget _buildMacroChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
