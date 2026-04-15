import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/youtube_service.dart';
import '../providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class ImportRecipeScreen extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialUrl;

  const ImportRecipeScreen({super.key, this.initialQuery, this.initialUrl});

  @override
  ConsumerState<ImportRecipeScreen> createState() => _ImportRecipeScreenState();
}

class _ImportRecipeScreenState extends ConsumerState<ImportRecipeScreen> {
  final _urlController = TextEditingController();
  final _searchController = TextEditingController();
  final YouTubeService _ytService = YouTubeService();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args.containsKey('query')) {
          _searchController.text = args['query'];
          _searchYouTube();
        }
        if (args.containsKey('url')) {
          _urlController.text = args['url'];
        }
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _searchController.dispose();
    _ytService.close();
    super.dispose();
  }

  Future<void> _searchYouTube() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final ytInstance = yt.YoutubeExplode();
      final results = await ytInstance.search.search(_searchController.text);
      ytInstance.close();
      
      if (!mounted) return;
      setState(() {
        _searchResults = results.take(10).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Search Error: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _isSearching = false);
    }
  }

  Future<void> _triggerManualImport(String url) async {
    if (url.isEmpty) return;

    // 1. Duplicate Check
    final recipes = ref.read(recipesProvider);
    final isDuplicate = recipes.any((r) => r.youtubeUrl == url || (r.youtubeUrl != null && url.contains(r.youtubeUrl!)));
    
    if (isDuplicate) {
      _showDuplicateDialog();
      _urlController.clear();
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
        const SnackBar(content: Text('AI Magic extraction started! Check Home.')),
      );
      Navigator.pop(context);
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
        content: const Text("AI Magic Import requires a Gemini API Key. Would you like to set it up now?"),
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
    final localRecipes = ref.watch(recipesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Import Recipe',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
            onPressed: () => Navigator.pushNamed(context, '/help'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paste Video URL', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              "Paste a link from supported video platforms (like YouTube). Our AI will attempt to extract the full recipe for you.",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              enabled: true,
              decoration: InputDecoration(
                hintText: 'https://youtube.com/watch?v=...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
                  onPressed: () => _triggerManualImport(_urlController.text),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Text('Search Videos', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              enabled: true,
              decoration: InputDecoration(
                hintText: 'Search for recipes...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                  onPressed: _searchYouTube,
                ),
              ),
              onSubmitted: (_) => _searchYouTube(),
            ),
            const SizedBox(height: 24),
            if (_isSearching)
              Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final video = _searchResults[index];
                  final isImported = localRecipes.any((r) => r.youtubeUrl?.contains(video.id.value) ?? false);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: isImported ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
                    ),
                    child: InkWell(
                      onTap: () => _triggerManualImport(video.url),
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
                                Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
