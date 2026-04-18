import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/recipe.dart';
import '../models/validation_result.dart';
import '../utils/recipe_parser.dart';

/// [PROTECTED UI]: "The Culinary Curator" Design System
/// DO NOT REGRESS: This screen must maintain editorial typography (Noto Serif/Manrope)
/// and asymmetrical layout as per Stitch designs.
class RecipeDetailScreen extends ConsumerWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WakelockPlus.enable();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusBanner(recipe),

                  // Editorial Masthead Title
                  Text(recipe.dishName, style: theme.textTheme.displayMedium),
                  const SizedBox(height: 16),

                  // Minimalist Subtitle: Category & Time
                  Row(
                    children: [
                      Text(
                        recipe.category.toUpperCase(),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (recipe.cookingTime != null) ...[
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.cookingTime!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 48),
                  _buildNutritionGrid(context, theme),

                  const SizedBox(height: 56),
                  _buildSectionTitle(context, "INGREDIENTS", theme),
                  const SizedBox(height: 24),
                  ...RecipeParser.parseList(
                    recipe.ingredients,
                  ).map((item) => _buildIngredientItem(item, theme)),

                  const SizedBox(height: 56),
                  _buildSectionTitle(context, "INSTRUCTIONS", theme),
                  const SizedBox(height: 24),
                  ...RecipeParser.parseList(recipe.recipe).asMap().entries.map(
                    (entry) =>
                        _buildStepItem(entry.key + 1, entry.value, theme),
                  ),

                  if (recipe.notes != null && recipe.notes!.isNotEmpty) ...[
                    const SizedBox(height: 56),
                    _buildSectionTitle(context, "KITCHEN NOTES", theme),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        recipe.notes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => launchUrl(Uri.parse(recipe.youtubeUrl!)),
        backgroundColor: theme.colorScheme.onSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
        label: Text(
          "WATCH ON YOUTUBE",
          style: theme.textTheme.labelLarge?.copyWith(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner(Recipe recipe) {
    if (recipe.validationResult == ValidationResult.valid) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: recipe.validationResult == ValidationResult.lowConfidence
            ? const Color(0xFFFFF8E1)
            : const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(
            recipe.validationResult == ValidationResult.lowConfidence
                ? Icons.warning_amber_rounded
                : Icons.info_outline,
            size: 20,
            color: recipe.validationResult == ValidationResult.lowConfidence
                ? Colors.orange[900]
                : Colors.blue[900],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recipe.validationResult.userMessage(null),
              style: TextStyle(
                color: recipe.validationResult == ValidationResult.lowConfidence
                    ? Colors.orange[900]
                    : Colors.blue[900],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Styled Step Number
          Text(
            number.toString().padLeft(2, '0'),
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.primary.withOpacity(0.2),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(text, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 350.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black26,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 20),
        ),
        onPressed: () {
          WakelockPlus.disable();
          Navigator.pop(context);
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            recipe.thumbnailUrl != null
                ? CachedNetworkImage(
                    imageUrl: recipe.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                : Container(color: Colors.grey[300]),
            // Subtle editorial gradient overlay
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black45,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black38,
                  ],
                  stops: [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionGrid(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 8),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionItem(
            "KCAL",
            "${recipe.totalCalories?.round() ?? '-'}",
            theme,
          ),
          _buildNutritionItem(
            "KCAL/100G",
            "${recipe.caloriesPer100g?.round() ?? '-'}",
            theme,
          ),
          _buildNutritionItem(
            "GRAMS",
            "${recipe.totalWeightGrams?.round() ?? '-'}",
            theme,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 12),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 4,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 12),
        Container(width: 32, height: 3, color: theme.colorScheme.primary),
      ],
    );
  }
}
