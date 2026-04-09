import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatelessWidget {
  final String? section;

  const HelpScreen({super.key, this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5ED),
      appBar: AppBar(
        title: Text(
          'User Manual',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFFFF8C00),
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/manual.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF8C00)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading manual: ${snapshot.error}'));
          }

          final fullContent = snapshot.data ?? '';
          String displayContent = fullContent;

          if (section != null && section != 'HOME') {
            final sections = fullContent.split('## ');
            final targetSection = sections.firstWhere(
              (s) => s.startsWith('[$section]'),
              orElse: () => fullContent,
            );
            
            if (targetSection != fullContent) {
              displayContent = '# HELP: $section\n\n## ' + targetSection;
            }
          }

          return Markdown(
            data: displayContent,
            styleSheet: MarkdownStyleSheet(
              h1: GoogleFonts.plusJakartaSans(color: const Color(0xFFFF8C00), fontSize: 28, fontWeight: FontWeight.w900),
              h2: GoogleFonts.plusJakartaSans(color: const Color(0xFFFF8C00), fontSize: 20, fontWeight: FontWeight.bold),
              p: GoogleFonts.beVietnamPro(color: Colors.grey[800], fontSize: 16, height: 1.5),
              listBullet: const TextStyle(color: Color(0xFFFF8C00), fontWeight: FontWeight.bold),
              code: GoogleFonts.shareTechMono(backgroundColor: Colors.orange.withOpacity(0.1), color: const Color(0xFFFF8C00)),
              horizontalRuleDecoration: BoxDecoration(
                border: Border(top: BorderSide(color: const Color(0xFFFF8C00).withOpacity(0.2), width: 1)),
              ),
            ),
          );
        },
      ),
    );
  }
}
