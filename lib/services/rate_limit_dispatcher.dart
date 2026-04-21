import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../services/logger/app_logger.dart';

enum ApiType { gemini, youtube }

/// [SYSTEM INTEGRITY]: The Gatekeeper for all external API traffic.
/// Enforces a strict "Invulnerability Window" between calls to prevent 429 errors.
class RateLimitDispatcher {
  final AppLogger _logger = AppLogger();
  
  // Default values in case config load fails
  int _geminiCooldown = 5000;
  int _youtubeCooldown = 2000;

  final Map<ApiType, DateTime> _lastCallFinished = {};
  final Map<ApiType, Future<void>> _locks = {};

  RateLimitDispatcher() {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final String response = await rootBundle.loadString('assets/rate_limit_config.json');
      final data = await json.decode(response);
      _geminiCooldown = data['gemini_cooldown_ms'] ?? 5000;
      _youtubeCooldown = data['youtube_cooldown_ms'] ?? 2000;
      _logger.info("RateLimitDispatcher initialized with config: Gemini ${_geminiCooldown}ms, YouTube ${_youtubeCooldown}ms");
    } catch (e) {
      _logger.warn("Failed to load rate_limit_config.json, using defaults.");
    }
  }

  /// Dispatches a task to the specific API queue, enforcing cooldowns.
  Future<T> dispatch<T>({
    required ApiType type,
    required Future<T> Function() task,
    String? description,
    String? contextId,
  }) async {
    // Get or create the lock for this API type
    final previousTask = _locks[type] ?? Future.value();
    
    // Create a completer for the current task
    final completer = Completer<T>();
    
    // Chain the current task after the previous one
    _locks[type] = previousTask.then((_) async {
      try {
        final cooldown = type == ApiType.gemini ? _geminiCooldown : _youtubeCooldown;
        final lastFinished = _lastCallFinished[type];
        
        if (lastFinished != null) {
          final elapsed = DateTime.now().difference(lastFinished).inMilliseconds;
          if (elapsed < cooldown) {
            final waitTime = cooldown - elapsed;
            _logger.info("[Gatekeeper] Pacing $type call ($description). Waiting ${waitTime}ms...", contextId: contextId);
            await Future.delayed(Duration(milliseconds: waitTime));
          }
        }

        _logger.info("[Gatekeeper] Releasing $type call: $description", contextId: contextId);
        final result = await task();
        _lastCallFinished[type] = DateTime.now();
        completer.complete(result);
      } catch (e) {
        // Still update the timestamp on failure to prevent rapid-fire retries
        _lastCallFinished[type] = DateTime.now();
        completer.completeError(e);
      }
    });

    return completer.future;
  }
}
