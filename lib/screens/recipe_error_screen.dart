import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/recipe.dart';
import '../models/transcript_error.dart';
import '../models/video_length.dart';
import '../models/validation_result.dart';
import '../providers/providers.dart';

class RecipeErrorScreen extends ConsumerWidget {
  final Recipe recipe;

  const RecipeErrorScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRecipes = ref.watch(recipesProvider);
    final currentRecipe = allRecipes.firstWhere((r) => r.id == recipe.id, orElse: () => recipe);
    
    final isAwaitingLongConfirm = currentRecipe.importStatus == "Awaiting Confirmation (Long Video)";
    final isProcessing = currentRecipe.importStatus != "No transcript found" &&
                         currentRecipe.importStatus != "Completed" &&
                         currentRecipe.importStatus?.contains("Failed") != true &&
                         !isAwaitingLongConfirm;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                isProcessing ? "PROCESSING\nRECIPE..." : "MISSING INGREDIENTS &\nINSTRUCTIONS",
                style: GoogleFonts.notoSerif(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.5,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),
              if (isProcessing) ...[
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF944A00),
                ),
                const SizedBox(height: 16),
                Text(
                  currentRecipe.importStatus ?? "Working on it...",
                  style: GoogleFonts.shareTechMono(
                    fontSize: 14,
                    color: const Color(0xFF944A00),
                    letterSpacing: 1,
                  ),
                ),
              ] else if (isAwaitingLongConfirm)
                Text(
                  "This video is over an hour long and may contain multiple recipes. Results may be incomplete. Continue anyway?",
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    String message = currentRecipe.transcriptError.userMessage;
                    
                    if (currentRecipe.validationResult != ValidationResult.valid) {
                      message = currentRecipe.validationResult.userMessage(currentRecipe.flavorProfile);
                    } else if (currentRecipe.transcriptError == TranscriptFetchError.unsupportedLanguage) {
                      final langName = Recipe.getLanguageName(currentRecipe.category);
                      message = "This video's transcript is in $langName. Only English is supported right now.";
                    }

                    return Text(
                      currentRecipe.importStatus == "No transcript found"
                          ? message
                          : "The AI encountered an error while processing this recipe: ${currentRecipe.importStatus}",
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.grey[700],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 60),
              Center(
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(
                    isProcessing ? Icons.auto_awesome : Icons.restaurant_menu,
                    size: 200,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 60),
              if (!isProcessing) ...[
                if (isAwaitingLongConfirm) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => ref.read(recipesProvider.notifier).confirmLongVideoProcessing(currentRecipe),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text("CONTINUE ANYWAY", style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      final resetRecipe = currentRecipe.copyWith(
                        importStatus: "Placeholder Created",
                        transcriptError: TranscriptFetchError.none,
                        validationResult: ValidationResult.valid,
                      );
                      await ref.read(recipesProvider.notifier).updateRecipe(resetRecipe);
                      await ref.read(recipesProvider.notifier).autoProcessRecipe(resetRecipe);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF944A00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      elevation: 0,
                    ),
                    child: Text(
                      "TRY RE-EXTRACTING",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => _showManualPasteDialog(context, ref, currentRecipe),
                    icon: const Icon(Icons.paste),
                    label: Text(
                      "PASTE TRANSCRIPT MANUALLY",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF944A00),
                      side: const BorderSide(color: Color(0xFF944A00), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Recipe?"),
                          content: const Text("This will remove the placeholder from your kitchen."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text("Delete", style: TextStyle(color: Colors.red))
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await ref.read(recipesProvider.notifier).deleteRecipe(currentRecipe.id!);
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      "DELETE PLACEHOLDER",
                      style: GoogleFonts.manrope(fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ] else
                Center(
                  child: Text(
                    "Please wait while we try again...",
                    style: GoogleFonts.manrope(fontStyle: FontStyle.italic, color: Colors.grey[600]),
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () => launchUrl(Uri.parse(currentRecipe.youtubeUrl!)),
                  child: Text(
                    "WATCH VIDEO",
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF944A00),
                      letterSpacing: 2,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualPasteDialog(BuildContext context, WidgetRef ref, Recipe recipe) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Paste Transcript"),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: "Paste the transcript here...",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(recipesProvider.notifier).updateManualTranscript(recipe, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Process"),
          ),
        ],
      ),
    );
  }
}
