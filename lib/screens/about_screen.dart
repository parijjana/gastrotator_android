import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final version = snapshot.data?.version ?? "1.0.0";
          final buildNumber = snapshot.data?.buildNumber ?? "1";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(Icons.restaurant_menu, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'GastRotator',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version $version ($buildNumber)',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                const Text(
                  'A decentralized, AI-powered recipe manager for the modern kitchen. Transform YouTube videos into beautiful, local kitchen guides instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                _buildLink(
                  context,
                  'Github Repository',
                  'https://github.com/parijjana/gastrotator_android',
                  Icons.code,
                ),
                const SizedBox(height: 12),
                _buildLink(
                  context,
                  'Report Issue / AI Feedback',
                  'https://github.com/parijjana/gastrotator_android/issues',
                  Icons.bug_report_outlined,
                ),
                
                const SizedBox(height: 48),
                _buildSectionHeader(context, "FUTURE HORIZONS (ROADMAP)"),
                const SizedBox(height: 16),
                _buildRoadmapCard(
                  context, 
                  "v2: The Cognitive Kitchen", 
                  "Phase 3 & 4 - High Priority",
                  [
                    RoadmapItem(
                      "Kinetic Weekly Planner", 
                      "Zero-waste meal scheduling that optimizes ingredients across your week."
                    ),
                    RoadmapItem(
                      "Intelligent Delta Grocery Lists", 
                      "Auto-generate shopping lists by comparing recipes to your current pantry."
                    ),
                    RoadmapItem(
                      "Iteration Tracking", 
                      "Log and rate your cooking attempts to track your progress and improvements."
                    ),
                    RoadmapItem(
                      "Pantry-to-Plate", 
                      "Vision-powered recognition to suggest recipes based on ingredients in your fridge."
                    ),
                    RoadmapItem(
                      "AI Ingredient Substitute Engine", 
                      "Smart, chemistry-based swaps for when you're missing a key ingredient."
                    ),
                    RoadmapItem(
                      "A/B Testing", 
                      "Save and compare multiple versions of the same recipe side-by-side."
                    ),
                    RoadmapItem(
                      "Global Flavor Translation", 
                      "Instant conversion of regional measurements (g vs oz) and terminology."
                    ),
                    RoadmapItem(
                      "Automated Nutrition Labeling", 
                      "Full macro-nutrient breakdown for every custom recipe you import."
                    ),
                    RoadmapItem(
                      "Multi-Step Timer Management", 
                      "Context-aware timers that sync with your specific cooking progress."
                    ),
                    RoadmapItem(
                      "Inventory Management", 
                      "Real-time alerts before your essential ingredients run low or expire."
                    ),
                  ],
                  Colors.orangeAccent,
                ),
                const SizedBox(height: 16),
                _buildRoadmapCard(
                  context, 
                  "v3: Future Connectivity", 
                  "Phase 5 - Long Term",
                  [
                    RoadmapItem(
                      "Structured Recipe Beaming", 
                      "Send perfectly formatted, interactive recipes to friends with a single tap."
                    ),
                    RoadmapItem(
                      "Oral Tradition (Voice-to-Recipe)", 
                      "Dictate family secret recipes directly into the app for instant structuring."
                    ),
                    RoadmapItem(
                      "Hands-Free Kitchen Assistant", 
                      "Voice control for scrolling and timer management while your hands are messy."
                    ),
                    RoadmapItem(
                      "Decentralized Multi-Device Sync", 
                      "Keep your data in sync across all devices without a central server."
                    ),
                    RoadmapItem(
                      "Smart Appliance Integration", 
                      "Sync temperatures and timers directly with compatible smart ovens."
                    ),
                    RoadmapItem(
                      "Dynamic Serving Scaling", 
                      "Instantly recalculate ingredient quantities for any number of guests."
                    ),
                  ],
                  Colors.blueAccent,
                ),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 24),
                const Text(
                  'Made with ❤️ for high-energy kitchens.',
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.shareTechMono(
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildRoadmapCard(BuildContext context, String title, String subtitle, List<RoadmapItem> items, Color accent) {
    return Card(
      elevation: 0,
      color: accent.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: accent.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, size: 18, color: accent),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("• ", style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(item.description, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLink(BuildContext context, String label, String url, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => launchUrl(Uri.parse(url)),
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class RoadmapItem {
  final String name;
  final String description;

  RoadmapItem(this.name, this.description);
}
