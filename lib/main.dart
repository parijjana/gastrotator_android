import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'screens/home_screen.dart';
import 'screens/import_recipe_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/recipe_detail_screen.dart';
import 'screens/about_screen.dart';
import 'screens/help_screen.dart';
import 'screens/recipe_error_screen.dart';
import 'providers/providers.dart';
import 'models/recipe.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: GastRotatorApp(),
    ),
  );
}

class GastRotatorApp extends ConsumerWidget {
  const GastRotatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSettings = ref.watch(themeProvider);

    return MaterialApp(
      title: 'GastRotator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.vibrantTheme.copyWith(
        brightness: themeSettings.brightness,
        colorScheme: AppTheme.vibrantTheme.colorScheme.copyWith(
          primary: themeSettings.primaryColor,
          brightness: themeSettings.brightness,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const _IntentHandler(child: HomeScreen()),
        '/import': (context) => const ImportRecipeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/about': (context) => const AboutScreen(),
        '/help': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return HelpScreen(section: args?['section']);
        },
        '/recipe-detail': (context) {
          final recipe = ModalRoute.of(context)!.settings.arguments as Recipe;
          return RecipeDetailScreen(recipe: recipe);
        },
        '/recipe-error': (context) {
          final recipe = ModalRoute.of(context)!.settings.arguments as Recipe;
          return RecipeErrorScreen(recipe: recipe);
        },
      },
    );
  }
}

class _IntentHandler extends ConsumerStatefulWidget {
  final Widget child;
  const _IntentHandler({required this.child});

  @override
  ConsumerState<_IntentHandler> createState() => _IntentHandlerState();
}

class _IntentHandlerState extends ConsumerState<_IntentHandler> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();

    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        _handleSharedText(value.first.path);
      }
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty && value.first.path.isNotEmpty) {
        ReceiveSharingIntent.instance.reset();
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
    final url = urlMatch?.group(0) ?? sharedText;

    if (!url.contains('youtube.com') && !url.contains('youtu.be')) return;

    final timestamp = DateTime.now().toString().split('.').first;
    final placeholder = Recipe(
      dishName: "Shared: $timestamp",
      category: "Pending",
      ingredients: "",
      recipe: "",
      youtubeUrl: url,
      importStatus: "Placeholder Created",
    );

    await ref.read(recipesProvider.notifier).addRecipe(placeholder);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
