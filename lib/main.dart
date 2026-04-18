import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'screens/home_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/recipe_error_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/log_screen.dart';
import 'screens/about_screen.dart';
import 'data/database_helper.dart';
import 'theme/app_theme.dart';
import 'providers/providers.dart';
import 'models/recipe.dart';
import 'models/validation_result.dart';
import 'services/logger/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger().init();
  runApp(const ProviderScope(child: GastRotatorApp()));
}

class GastRotatorApp extends ConsumerWidget {
  const GastRotatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);
    
    // Eagerly initialize the API Key at boot-up
    ref.watch(apiKeyProvider);

    return MaterialApp(
      title: 'GastRotator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(themeSettings.primaryColor),
      darkTheme: AppTheme.dark(themeSettings.primaryColor),
      themeMode: themeSettings.brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      initialRoute: '/',
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const GlobalMagicOverlay(),
          ],
        );
      },
      routes: {
        '/': (context) => const IntentHandler(child: MainNavigationScreen()),
        '/settings': (context) => const SettingsScreen(),
        '/help': (context) => const HelpScreen(),
        '/logs': (context) => const LogScreen(),
        '/about': (context) => const AboutScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/recipe-detail') {
          final recipe = settings.arguments as Recipe;
          return MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          );
        }
        if (settings.name == '/recipe-error') {
          final recipe = settings.arguments as Recipe;
          return MaterialPageRoute(
            builder: (context) => RecipeErrorScreen(recipe: recipe),
          );
        }
        return null;
      },
    );
  }
}

class GlobalMagicOverlay extends ConsumerWidget {
  const GlobalMagicOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(magicOverlayProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isVisible
          ? Container(
              key: const ValueKey('magic_overlay'),
              color: const Color(0xFFFCF9F8).withOpacity(0.9),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF944A00),
                      size: 120,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "ENTERING THE KITCHEN...",
                      style: GoogleFonts.notoSerif(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Extraction Started.",
                      style: GoogleFonts.shareTechMono(
                        fontSize: 16,
                        color: const Color(0xFF944A00),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class IntentHandler extends ConsumerStatefulWidget {
  final Widget child;
  const IntentHandler({super.key, required this.child});

  @override
  ConsumerState<IntentHandler> createState() => _IntentHandlerState();
}

class _IntentHandlerState extends ConsumerState<IntentHandler> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    // For sharing or opening urls from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      if (value.isNotEmpty) {
        _handleSharedText(value.first.path);
      }
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening urls from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      if (value.isNotEmpty) {
        _handleSharedText(value.first.path);
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  Future<void> _handleSharedText(String sharedText) async {
    final urlMatch = RegExp(r'(https?://[^\s]+)').firstMatch(sharedText);
    final url = (urlMatch?.group(0) ?? sharedText).trim();

    if (!url.contains('youtube.com') && !url.contains('youtu.be')) return;

    try {
      // Trigger Overlay
      ref.read(magicOverlayProvider.notifier).show();
      
      await ref.read(recipesProvider.notifier).triggerMagicImport(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI Magic extraction started!')),
        );
        // Navigate back to Home
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import Error: $e')),
        );
      }
    } finally {
      // Hide Overlay after 1.5s
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) ref.read(magicOverlayProvider.notifier).hide();
      });
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
