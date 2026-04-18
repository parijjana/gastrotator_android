import 'dart:convert';
import 'package:http/http.dart' as http;

/// A standalone script to test the "Model Ladder" discovery and fallback logic.
/// This simulates how the app will dynamically find the best working model.

class ModelLadder {
  final String apiKey;
  
  // Priority order for families
  static const List<String> _priorityKeywords = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-1.0-pro',
  ];

  ModelLadder(this.apiKey);

  /// 1. Fetch ALL available models for this API Key
  Future<List<String>> discoverModels() async {
    print("--- STEP 1: Fetching available models from Google AI API ---");
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
        
        // Filter: Must be Gemini, must support generation, must NOT be experimental
        if (name.contains('gemini') && 
            methods.contains('generateContent') && 
            !name.contains('experimental')) {
          validNames.add(name.replaceFirst('models/', ''));
        }
      }
      
      print("Found ${validNames.length} eligible Gemini models.");
      return validNames;
    } catch (e) {
      print("Discovery Error: $e");
      return [];
    }
  }

  /// 2. Sort discovered models into a "Ladder" based on our priority
  List<String> buildLadder(List<String> discovered) {
    print("\n--- STEP 2: Building the Priority Ladder ---");
    List<String> ladder = [];

    // First, add models that match our priority keywords in order
    for (var keyword in _priorityKeywords) {
      final matches = discovered.where((m) => m.contains(keyword)).toList();
      // Sort within the group (e.g., flash-002 before flash-001)
      matches.sort((a, b) => b.compareTo(a));
      ladder.addAll(matches);
    }

    // Add any remaining gemini models that weren't in our keyword list
    final remaining = discovered.where((m) => !ladder.contains(m)).toList();
    remaining.sort((a, b) => b.compareTo(a));
    ladder.addAll(remaining);

    print("Final Model Ladder: ${ladder.join(' -> ')}");
    return ladder;
  }

  /// 3. Execute with Fallback (The "Ladder" Logic)
  Future<void> runWithFallback(List<String> ladder, String prompt) async {
    print("\n--- STEP 3: Executing with Fallback ---");
    
    for (String modelName in ladder) {
      print("Attempting with [$modelName]...");
      try {
        final success = await _simulateApiCall(modelName, prompt);
        if (success) {
          print("SUCCESS! Model [$modelName] handled the request.");
          return;
        }
      } catch (e) {
        print("FAILED [$modelName]: $e");
        print("Moving to next rung on the ladder...");
      }
    }
    
    print("CRITICAL: All models on the ladder failed.");
  }

  /// Mocking an API call to test the ladder behavior
  Future<bool> _simulateApiCall(String modelName, String prompt) async {
    final url = Uri.parse("https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey");
    
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [
          {
            'parts': [{'text': prompt}]
          }
        ]
      }),
    );

    if (response.statusCode == 200) return true;
    
    // Simulate specific error handling
    if (response.statusCode == 503) throw "Service Unavailable (Overloaded)";
    if (response.statusCode == 404) throw "Model Not Found (Deprecated)";
    
    throw "Error ${response.statusCode}: ${response.body}";
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print("Usage: dart test_model_ladder.dart YOUR_API_KEY");
    return;
  }

  final String apiKey = args[0];
  final engine = ModelLadder(apiKey);

  // 1. Discover
  final discovered = await engine.discoverModels();
  if (discovered.isEmpty) return;

  // 2. Rank
  final ladder = engine.buildLadder(discovered);

  // 3. Test Fallback
  await engine.runWithFallback(ladder, "Say 'Hello Ladder' in 3 languages.");
}
