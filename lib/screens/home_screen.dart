import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/recipe.dart';
import '../providers/providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "All";
  List<dynamic> _fallbackYoutubeResults = [];
  bool _isSearchingYoutube = false;
  Timer? _debounce;
  int? _shakingRecipeId; // New state for shake animation

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _triggerYoutubeFallback(query);
      } else {
        setState(() => _fallbackYoutubeResults = []);
      }
    });
  }

  Future<void> _triggerYoutubeFallback(String query) async {
    final recipes = ref.read(recipesProvider);
    final localMatches = recipes.where((r) => r.dishName.toLowerCase().contains(query.toLowerCase())).toList();
    
    if (localMatches.isEmpty) {
      setState(() => _isSearchingYoutube = true);
      try {
        final ytInstance = yt.YoutubeExplode();
        final results = await ytInstance.search.search(query);
        ytInstance.close();
        setState(() => _fallbackYoutubeResults = results.take(5).toList());
      } catch (e) {
        print("Fallback Search Error: $e");
      } finally {
        setState(() => _isSearchingYoutube = false);
      }
    } else {
      setState(() => _fallbackYoutubeResults = []);
    }
  }

  Future<void> _triggerDirectImport(String url) async {
    // 1. Duplicate Check
    final recipes = ref.read(recipesProvider);
    final isDuplicate = recipes.any((r) => r.youtubeUrl == url || (r.youtubeUrl != null && url.contains(r.youtubeUrl!)));
    
    if (isDuplicate) {
      _showDuplicateDialog();
      return;
    }

    // 2. API Key Guard
    final apiKey = ref.read(apiKeyProvider);
    if (apiKey == null || apiKey.isEmpty) {
      _showNoKeyDialog();
      return;
    }

    await ref.read(recipesProvider.notifier).triggerMagicImport(url);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Magic extraction started!')),
      );
    }
  }

  void _showDuplicateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Duplicate Video"),
        content: const Text("This recipe is already in your kitchen!"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it"))],
      ),
    );
  }

  void _showNoKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gemini Key Missing"),
        content: const Text("Magic Import requires a Gemini API Key. Would you like to set it up now?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Later")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
            child: const Text("Go to Settings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(recipesProvider);
    final themeSettings = ref.watch(themeProvider);

    final categories = ["All", "Breakfast", "Lunch", "Dinner", "Dessert", "Snack"];

    final filteredRecipes = recipes.where((r) {
      final matchesSearch = r.dishName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == "All" || 
                              r.category.split(',').map((c) => c.trim()).contains(_selectedCategory);
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(
              'GastRotator',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: Opacity(
                opacity: 0.3, // Nondescript
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: themeSettings.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant_menu, size: 16, color: Colors.white),
                ),
              ),
              onPressed: () => Navigator.pushNamed(context, '/about'),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pushNamed(context, '/help', arguments: {'section': 'HOME'});
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "WHAT ARE WE\nCOOKING TODAY?",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Search your collection...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged("");
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, "VIBE CHECK"),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (val) {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedCategory = cat);
                            },
                            selectedColor: themeSettings.primaryColor,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : themeSettings.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (filteredRecipes.isEmpty && _fallbackYoutubeResults.isEmpty && !_isSearchingYoutube)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      recipes.isEmpty ? 'Your kitchen is empty!' : 'No matches found.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (recipes.isEmpty) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.read(recipesProvider.notifier).loadSamples(),
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text("Load Sample Recipes"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeSettings.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else ...[
            if (filteredRecipes.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < filteredRecipes.length) {
                        final recipe = filteredRecipes[index];
                        return _buildRecipeCard(context, ref, recipe);
                      } else {
                        // "Find More" button at the end of local results
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/import', arguments: {'query': _searchQuery}),
                            icon: const Icon(Icons.search),
                            label: Text("Find more '$_searchQuery' on YouTube"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        );
                      }
                    },
                    childCount: _searchQuery.isNotEmpty ? filteredRecipes.length + 1 : filteredRecipes.length,
                  ),
                ),
              ),
            
            if (_searchQuery.isNotEmpty && filteredRecipes.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                  child: Column(
                    children: [
                      const Divider(thickness: 1, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        "NO RECIPES SAVED",
                        style: GoogleFonts.shareTechMono(color: Colors.grey, fontSize: 12, letterSpacing: 2),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.movie_filter_outlined, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text("SUGGESTIONS FROM YOUTUBE", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_isSearchingYoutube)
              const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
              ),

            if (_fallbackYoutubeResults.isNotEmpty && filteredRecipes.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final video = _fallbackYoutubeResults[index];
                      return _buildYoutubeFallbackCard(context, video, recipes);
                    },
                    childCount: _fallbackYoutubeResults.length,
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pushNamed(context, '/import');
        },
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI Magic Import'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("See All", style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildRecipeCard(BuildContext context, WidgetRef ref, Recipe recipe) {
    return ShakeWidget(
      shake: _shakingRecipeId == recipe.id,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
        onTap: (recipe.importStatus == "Completed" || recipe.importStatus?.contains("Failed") == true || recipe.importStatus?.contains("No transcript") == true)
            ? () {
                HapticFeedback.lightImpact();
                if (recipe.importStatus == "Completed") {
                  Navigator.pushNamed(context, '/recipe-detail', arguments: recipe);
                } else {
                  Navigator.pushNamed(context, '/recipe-error', arguments: recipe);
                }
              }
            : null,
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: CachedNetworkImage(
                  imageUrl: recipe.thumbnailUrl!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 150,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ListTile(
              title: Text(
                recipe.dishName,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
              subtitle: recipe.importStatus == "Completed"
                  ? Text("${recipe.category} • ${recipe.totalCalories?.toStringAsFixed(0) ?? 0} kcal")
                  : Text(
                      recipe.importStatus ?? "Pending...",
                      style: TextStyle(
                        color: recipe.importStatus?.contains("Failed") == true || recipe.importStatus?.contains("No transcript") == true ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, ref, recipe),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildYoutubeFallbackCard(BuildContext context, dynamic video, List<Recipe> localRecipes) {
    final isImported = localRecipes.any((r) => r.youtubeUrl?.contains(video.id.value) ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: isImported ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _triggerDirectImport(video.url),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(video.thumbnails.lowResUrl, width: 100, height: 60, fit: BoxFit.cover),
                  ),
                  if (isImported)
                    Positioned(
                      bottom: 2,
                      left: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(video.author, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline, color: Colors.red),
                    onPressed: () => launchUrl(Uri.parse(video.url)),
                  ),
                  const Icon(Icons.add_circle_outline, color: Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Recipe recipe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Recipe?"),
        content: Text("Are you sure you want to delete '${recipe.dishName}'?"),
        actions: [
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
              setState(() => _shakingRecipeId = recipe.id);
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) setState(() => _shakingRecipeId = null);
              });
            }, 
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              ref.read(recipesProvider.notifier).deleteRecipe(recipe.id!);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class ShakeWidget extends StatelessWidget {
  final Widget child;
  final bool shake;

  const ShakeWidget({super.key, required this.child, required this.shake});

  @override
  Widget build(BuildContext context) {
    if (!shake) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(shake),
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        final double offset = (value < 0.2 || (value > 0.4 && value < 0.6) || value > 0.8) ? 10.0 : -10.0;
        if (value >= 1.0) return child!;
        return Transform.translate(
          offset: Offset(offset * (1.0 - value), 0),
          child: child,
        );
      },
      child: child,
    );
  }
}
