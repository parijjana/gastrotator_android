import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../../data/database_helper.dart';

enum LogLevel { info, warning, error }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? technicalDetails;
  final String? contextId;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.technicalDetails,
    this.contextId,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'technical_details': technicalDetails,
      'context_id': contextId,
    };
  }

  factory LogEntry.fromMap(Map<String, dynamic> map) {
    return LogEntry(
      timestamp: DateTime.parse(map['timestamp']),
      level: LogLevel.values.firstWhere((e) => e.name == map['level']),
      message: map['message'],
      technicalDetails: map['technical_details'],
      contextId: map['context_id'],
    );
  }
}

class AppLogger extends ChangeNotifier {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  final List<LogEntry> _logs = [];
  final int _maxLogs = 500;
  bool _isInitialized = false;

  UnmodifiableListView<LogEntry> get logs => UnmodifiableListView(_logs);

  Future<void> init() async {
    if (_isInitialized) return;
    final dbLogs = await DatabaseHelper.instance.getAllLogs();
    _logs.clear();
    _logs.addAll(dbLogs.map((m) => LogEntry.fromMap(m)));
    _isInitialized = true;
    notifyListeners();
  }

  void log(
    String message, {
    LogLevel level = LogLevel.info,
    String? details,
    String? apiKeyToMask,
    String? contextId,
  }) {
    String sanitizedMessage = message;
    String? sanitizedDetails = details;

    if (apiKeyToMask != null && apiKeyToMask.isNotEmpty) {
      sanitizedMessage = sanitizedMessage.replaceAll(
        apiKeyToMask,
        '***API_KEY_MASKED***',
      );
      sanitizedDetails = sanitizedDetails?.replaceAll(
        apiKeyToMask,
        '***API_KEY_MASKED***',
      );
    }

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: sanitizedMessage,
      technicalDetails: sanitizedDetails,
      contextId: contextId,
    );

    _logs.insert(0, entry);
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }

    // Fire and forget database operations
    _persistLog(entry);

    debugPrint('[${entry.level.name.toUpperCase()}] ${entry.message} ${contextId != null ? "($contextId)" : ""}');
    notifyListeners();
  }

  Future<void> _persistLog(LogEntry entry) async {
    try {
      await DatabaseHelper.instance.insertLog(entry.toMap());
      await DatabaseHelper.instance.pruneLogs(_maxLogs);
    } catch (e) {
      debugPrint("Log Persistence Warning: $e");
    }
  }

  void info(String message, {String? details, String? apiKeyToMask, String? contextId}) => log(
    message,
    level: LogLevel.info,
    details: details,
    apiKeyToMask: apiKeyToMask,
    contextId: contextId,
  );

  void warn(String message, {String? details, String? apiKeyToMask, String? contextId}) => log(
    message,
    level: LogLevel.warning,
    details: details,
    apiKeyToMask: apiKeyToMask,
    contextId: contextId,
  );

  void error(String message, {String? details, String? apiKeyToMask, String? contextId}) => log(
    message,
    level: LogLevel.error,
    details: details,
    apiKeyToMask: apiKeyToMask,
    contextId: contextId,
  );

  void clear() async {
    _logs.clear();
    try {
      await DatabaseHelper.instance.clearLogs();
    } catch (e) {
      debugPrint("Log Clear Warning: $e");
    }
    notifyListeners();
  }
}
