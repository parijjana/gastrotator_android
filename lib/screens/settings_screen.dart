import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(apiKeyProvider);
    if (currentKey != null) {
      _apiKeyController.text = currentKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _exportCollection() async {
    setState(() => _isProcessing = true);
    try {
      final jsonData = await ref.read(recipesProvider.notifier).exportRecipes();
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${directory.path}/gastrotator_backup_$timestamp.json');
      await tempFile.writeAsString(jsonData);
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'GastRotator Recipe Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _importCollection() async {
    setState(() => _isProcessing = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Crucial for some Android URIs
      );

      if (result != null && result.files.single.bytes != null) {
        final jsonString = String.fromCharCodes(result.files.single.bytes!);
        await ref.read(recipesProvider.notifier).importRecipes(jsonString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Collection imported successfully!')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeSettings = ref.watch(themeProvider);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: themeSettings.brightness == Brightness.light ? const Color(0xFFFFF5ED) : null,
          appBar: AppBar(
            title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildSectionTitle(context, "Gemini API Key"),
              const SizedBox(height: 16),
              Card(
                color: themeSettings.primaryColor.withOpacity(0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: themeSettings.primaryColor.withOpacity(0.2))),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: themeSettings.primaryColor),
                          const SizedBox(width: 12),
                          const Expanded(child: Text("Recipe extraction requires a free Google Gemini API Key.", style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => launchUrl(Uri.parse("https://aistudio.google.com/app/apikey")),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text("Get Your Free Key at Google AI Studio"),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _apiKeyController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter your API key',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: () {
                      ref.read(apiKeyProvider.notifier).saveKey(_apiKeyController.text);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key saved securely.')));
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildSectionTitle(context, "Backup & Restore"),
              const SizedBox(height: 16),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.download, color: Colors.blue),
                title: const Text("Export Collection"),
                subtitle: const Text("Save your recipes to a JSON file"),
                onTap: _exportCollection,
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: const Icon(Icons.upload, color: Colors.green),
                title: const Text("Import Collection"),
                subtitle: const Text("Restore recipes from a backup file"),
                onTap: _importCollection,
              ),
              const SizedBox(height: 40),
              _buildSectionTitle(context, "Visual Identity"),
              const SizedBox(height: 16),
              _buildThemeSelector(context, ref, themeSettings),
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/about'),
                  child: const Text("About GastRotator"),
                ),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildThemeSelector(BuildContext context, WidgetRef ref, ThemeSettings settings) {
    final colors = [const Color(0xFFFF8C00), Colors.deepPurple, Colors.teal, Colors.blueGrey];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: colors.map((color) {
        return GestureDetector(
          onTap: () => ref.read(themeProvider.notifier).setPrimaryColor(color),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: settings.primaryColor == color ? Colors.black : Colors.transparent, width: 3),
            ),
          ),
        );
      }).toList(),
    );
  }
}
