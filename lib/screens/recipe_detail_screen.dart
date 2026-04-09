import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/recipe.dart';
import '../utils/unit_converter.dart';

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Enable wakelock when entering the recipe detail screen
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    // Disable wakelock when leaving the screen
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> _launchUrl() async {
    if (widget.recipe.youtubeUrl == null) return;
    final Uri url = Uri.parse(widget.recipe.youtubeUrl!);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white),
                onPressed: () {
                  Navigator.pushNamed(context, '/help', arguments: {'section': 'DETAIL'});
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: recipe.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: recipe.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(context),
                      errorWidget: (context, url, error) => _buildPlaceholder(context),
                    )
                  : _buildPlaceholder(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.dishName,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Vertical Tags
                  _buildChip(context, recipe.category, Icons.category_outlined),
                  const SizedBox(height: 8),
                  _buildChip(context, "${recipe.totalCalories?.toStringAsFixed(0) ?? 0} kcal", Icons.local_fire_department_outlined),
                  const SizedBox(height: 8),
                  _buildChip(context, "${recipe.caloriesPer100g?.toStringAsFixed(0) ?? 0} kcal/100g", Icons.scale_outlined),
                  const SizedBox(height: 8),
                  _buildChip(context, "${recipe.totalWeightGrams?.toStringAsFixed(0) ?? 0} g", Icons.monitor_weight_outlined),
                  const SizedBox(height: 8),
                  _buildChip(context, recipe.cookingTime ?? "Time: Unknown", Icons.timer_outlined),
                  
                  const SizedBox(height: 24),
                  // YouTube Info
                  if (recipe.youtubeChannel != null)
                    Text(
                      "Channel: ${recipe.youtubeChannel}",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  if (recipe.youtubeUrl != null)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _launchUrl();
                      },
                      child: Text(
                        recipe.youtubeUrl!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "Ingredients"),
                  const SizedBox(height: 16),
                  ...recipe.ingredients.split('\n').where((s) => s.isNotEmpty).map((item) {
                    final isHeader = item.trim().endsWith(':');
                    final processedText = isHeader ? item : UnitConverter.convertString(item);
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: isHeader ? 8 : 12,
                        top: isHeader ? 12 : 0,
                        left: isHeader ? 0 : 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isHeader)
                            Icon(Icons.check_circle_outline, size: 18, color: Theme.of(context).colorScheme.secondary),
                          if (!isHeader) const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              processedText,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                                color: isHeader ? Theme.of(context).colorScheme.primary : null,
                                fontSize: isHeader ? 18 : 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle(context, "Instructions"),
                  const SizedBox(height: 16),
                  ...recipe.recipe.split('\n').where((s) => s.isNotEmpty).map((step) => Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              step.trim().startsWith(RegExp(r'\d')) ? step.split('.').first : "",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Text(step.trim().startsWith(RegExp(r'\d')) && step.contains('.') ? step.substring(step.indexOf('.') + 1).trim() : step, style: Theme.of(context).textTheme.bodyLarge)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _launchUrl();
                      },
                      icon: const Icon(Icons.play_circle_outline),
                      label: const Text("Open on YouTube"),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withAlpha(25),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: Theme.of(context).colorScheme.primary.withAlpha(128),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }
}
