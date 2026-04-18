import 'dart:convert';
import 'package:http/http.dart' as http;

/// A standalone script to test the NEW "Model Ladder" discovery logic.
/// Supports both MOCK and LIVE API data.

class NewModelLadder {
  // New Viable Keywords (No versions)
  static const List<String> _viableKeywords = ['flash', 'gemma'];

  /// Filters and ranks models based on the new logic
  List<String> buildLadder(List<String> discovered) {
    print("\n--- BUILDING THE NEW LADDER (Flash & Gemma Priority) ---");
    List<String> ladder = [];

    // 1. Process 'flash' and 'gemma' groups first
    for (var keyword in _viableKeywords) {
      final group = discovered.where((m) => m.toLowerCase().contains(keyword)).toList();
      // Sort within group (descending so newer versions/names typically come first)
      group.sort((a, b) => b.compareTo(a));
      ladder.addAll(group);
      print("Found ${group.length} models for keyword '$keyword': ${group.join(', ')}");
    }

    // 2. The ladder now consists ONLY of 'flash' and 'gemma' families.
    // We explicitly exclude Pro or specialized Gemini models to ensure compatibility with free tiers.

    print("\nFINAL RANKED LADDER (Free-Tier Viable):");
    if (ladder.isEmpty) {
      print("No models discovered. Returning version-agnostic fallback.");
      return ['gemini-flash-latest'];
    }
    
    for (int i = 0; i < ladder.length; i++) {
      print("${i + 1}. ${ladder[i]}");
    }
    
    return ladder;
  }

  /// Fetches LIVE models from the Google AI API
  Future<List<String>> discoverLiveModels(String apiKey) async {
    print("\n--- STEP 1: Fetching LIVE models from Google AI API ---");
    try {
      final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey");
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw "Failed to list models: ${response.statusCode} - ${response.body}";
      }

      final data = json.decode(response.body);
      final List<dynamic> rawModels = data['models'] ?? [];
      
      List<String> validNames = [];

      for (var m in rawModels) {
        final String name = m['name'] ?? "";
        final List<dynamic> methods = m['supportedGenerationMethods'] ?? [];
        
        // Filter: Must be Gemini/Gemma, must support generation
        final nameLower = name.toLowerCase();
        if ((nameLower.contains('gemini') || nameLower.contains('gemma')) && 
            methods.contains('generateContent')) {
          validNames.add(name.replaceFirst('models/', ''));
        }
      }
      
      print("Found ${validNames.length} eligible candidates in your account.");
      return validNames;
    } catch (e) {
      print("Discovery Error: $e");
      return [];
    }
  }
}

void runMockTest() {
  print("\n=== RUNNING MOCK FILTER TEST ===");
  
  // A representative list of what the Google AI API might return
  final List<String> mockDiscovered = [
    'gemini-2.0-flash-exp',
    'gemini-2.0-flash-001',
    'gemini-1.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
    'gemini-1.0-pro',
    'gemma-2b-it',
    'gemma-7b',
    'learnlm-1.5-pro-experimental',
    'embedding-001',
    'text-embedding-004'
  ];

  print("Mock API discovered models: ${mockDiscovered.join(', ')}");
  
  // Apply our custom exclusion rules
  final List<String> eligible = mockDiscovered.where((m) {
    final name = m.toLowerCase();
    final isViableFamily = name.contains('gemini') || name.contains('gemma');
    final isExperimental = name.contains('experimental') || name.contains('-exp');
    final isDeprecated = name.contains('deprecated');
    
    return isViableFamily && !isExperimental && !isDeprecated;
  }).toList();

  final ladderEngine = NewModelLadder();
  ladderEngine.buildLadder(eligible);
}

void main(List<String> args) async {
  final ladderEngine = NewModelLadder();

  if (args.isEmpty) {
    print("No API Key provided. Running mock test by default.");
    runMockTest();
    print("\nTo run with a live key: dart test_new_model_ladder.dart YOUR_API_KEY");
    return;
  }

  final String apiKey = args[0];
  print("=== RUNNING LIVE API TEST ===");
  
  final liveModels = await ladderEngine.discoverLiveModels(apiKey);
  
  if (liveModels.isNotEmpty) {
    // Apply our custom exclusion rules to live data
    final List<String> eligible = liveModels.where((m) {
      final name = m.toLowerCase();
      final isExperimental = name.contains('experimental') || name.contains('-exp');
      final isDeprecated = name.contains('deprecated');
      return !isExperimental && !isDeprecated;
    }).toList();

    ladderEngine.buildLadder(eligible);
  } else {
    print("No models found. Check your API key.");
  }
}
