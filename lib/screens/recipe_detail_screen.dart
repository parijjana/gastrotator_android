import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/recipe.dart';
import '../models/validation_result.dart';
import '../utils/unit_converter.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Enable wakelock when on this screen
    WakelockPlus.enable();

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (recipe.validationResult == ValidationResult.foodAdjacent || recipe.validationResult == ValidationResult.lowConfidence)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: recipe.validationResult == ValidationResult.lowConfidence ? Colors.orange[50] : Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: recipe.validationResult == ValidationResult.lowConfidence ? Colors.orange[200]! : Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            recipe.validationResult == ValidationResult.lowConfidence ? Icons.warning_amber_rounded : Icons.info_outline,
                            color: recipe.validationResult == ValidationResult.lowConfidence ? Colors.orange[800] : Colors.blue[800],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              recipe.validationResult.userMessage(null),
                              style: TextStyle(
                                color: recipe.validationResult == ValidationResult.lowConfidence ? Colors.orange[900] : Colors.blue[900],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    recipe.dishName,
                    style: GoogleFonts.notoSerif(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          recipe.category.toUpperCase(),
                          style: GoogleFonts.shareTechMono(
                            color: Colors.white,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      if (recipe.cookingTime != null) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.timer_outlined, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          recipe.cookingTime!,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildNutritionGrid(context),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "INGREDIENTS"),
                  const SizedBox(height: 16),
                  Text(
                    recipe.ingredients,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "INSTRUCTIONS"),
                  const SizedBox(height: 16),
                  Text(
                    recipe.recipe,
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  if (recipe.notes != null && recipe.notes!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    _buildSectionTitle(context, "TIPS & WARNINGS"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.yellow[50],
                        border: Border.all(color: Colors.yellow[200]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recipe.notes!,
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => launchUrl(Uri.parse(recipe.youtubeUrl!)),
        backgroundColor: Colors.black,
        icon: const Icon(Icons.play_circle_fill, color: Colors.white),
        label: Text(
          "WATCH ON YOUTUBE",
          style: GoogleFonts.shareTechMono(color: Colors.white, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          WakelockPlus.disable();
          Navigator.pop(context);
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: recipe.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: recipe.thumbnailUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              )
            : Container(color: Colors.black26),
      ),
    );
  }

  Widget _buildNutritionGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNutritionItem("CALORIES", "${recipe.totalCalories?.round() ?? '-'}"),
          _buildNutritionItem("KCAL/100G", "${recipe.caloriesPer100g?.round() ?? '-'}"),
          _buildNutritionItem("WEIGHT", "${recipe.totalWeightGrams?.round() ?? '-'}g"),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.shareTechMono(
            fontSize: 10,
            color: Colors.grey[600],
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.notoSerif(
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: GoogleFonts.shareTechMono(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: Colors.black,
      ),
    );
  }
}
