import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  final String? initialSection;

  const HelpScreen({super.key, this.initialSection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'GEMINI SETUP GUIDE',
          style: theme.textTheme.labelLarge?.copyWith(
            letterSpacing: 2,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get Your Free API Key',
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Follow these steps to unlock AI recipe extraction. It takes less than 2 minutes and is completely free.',
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
            ),
            
            const SizedBox(height: 56),
            _buildStep(
              context,
              "01",
              "Visit Google AI Studio",
              "Open the official portal where Google provides free access to Gemini for developers and enthusiasts.",
              buttonLabel: "OPEN AI STUDIO",
              onPressed: () => launchUrl(Uri.parse('https://aistudio.google.com/app/apikey')),
            ),
            
            _buildStep(
              context,
              "02",
              "Create API Key",
              "Once signed in, click the prominent blue button labeled 'Create API key'. If prompted, select 'Create API key in new project'.",
              showVisualPlaceholder: true,
              visualText: "CREATE API KEY",
            ),
            
            _buildStep(
              context,
              "03",
              "Copy the String",
              "A popup will appear with a long string of letters and numbers. Click the 'Copy' icon next to it. Keep this string private!",
              showVisualPlaceholder: true,
              visualText: "AIzaSyB... [COPY]",
            ),
            
            _buildStep(
              context,
              "04",
              "Paste in Settings",
              "Return to GastRotator and paste the copied string into the 'Gemini API Key' field in your settings.",
              buttonLabel: "GO TO SETTINGS",
              isPrimary: true,
              onPressed: () => Navigator.pushReplacementNamed(context, '/settings'),
            ),
            
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context, 
    String number, 
    String title, 
    String description, 
    {String? buttonLabel, 
    VoidCallback? onPressed, 
    bool showVisualPlaceholder = false,
    String? visualText,
    bool isPrimary = false}
  ) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 64.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                number,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          if (showVisualPlaceholder) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
              ),
              child: Center(
                child: Text(
                  visualText ?? "",
                  style: GoogleFonts.shareTechMono(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
          if (buttonLabel != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: isPrimary 
                ? ElevatedButton(
                    onPressed: onPressed,
                    child: Text(buttonLabel),
                  )
                : OutlinedButton(
                    onPressed: onPressed,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(buttonLabel, style: TextStyle(color: theme.colorScheme.primary)),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
