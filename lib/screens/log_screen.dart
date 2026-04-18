import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/logger/app_logger.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _logger.addListener(_onLogUpdated);
  }

  @override
  void dispose() {
    _logger.removeListener(_onLogUpdated);
    super.dispose();
  }

  void _onLogUpdated() {
    if (mounted) setState(() {});
  }

  Map<String, List<LogEntry>> _getGroupedLogs() {
    final Map<String, List<LogEntry>> grouped = {};
    for (var entry in _logger.logs) {
      final key = entry.contextId ?? "SYSTEM EVENTS";
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(entry);
    }
    return grouped;
  }

  String _generateLogText({String? filterContextId}) {
    final grouped = _getGroupedLogs();
    final buffer = StringBuffer();
    buffer.writeln("GastRotator System Logs - ${DateTime.now()}\n");

    if (filterContextId != null) {
      final entries = grouped[filterContextId];
      if (entries != null) {
        _writeGroupToBuffer(buffer, filterContextId, entries);
      }
    } else {
      grouped.forEach((context, entries) {
        _writeGroupToBuffer(buffer, context, entries);
      });
    }

    return buffer.toString();
  }

  void _writeGroupToBuffer(
    StringBuffer buffer,
    String context,
    List<LogEntry> entries,
  ) {
    buffer.writeln("=== CONTEXT: $context ===");
    for (var e in entries.reversed) {
      buffer.writeln(
        "[${e.timestamp}] ${e.level.name.toUpperCase()}: ${e.message}",
      );
      if (e.technicalDetails != null) {
        buffer.writeln("  Details: ${e.technicalDetails}");
      }
    }
    buffer.writeln("");
  }

  void _shareLogs({String? contextId}) {
    final text = _generateLogText(filterContextId: contextId);
    if (text.isEmpty) return;
    Share.share(
      text,
      subject: contextId != null
          ? 'GastRotator Logs: $contextId'
          : 'GastRotator Grouped Logs',
    );
  }

  void _copyLogs({String? contextId}) {
    final text = _generateLogText(filterContextId: contextId);
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          contextId != null
              ? 'Logs for $contextId copied'
              : 'All logs copied to clipboard',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupedLogs = _getGroupedLogs();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'SYSTEM LOGS',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_logger.logs.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_all_rounded, color: Colors.blue),
              onPressed: () => _copyLogs(),
              tooltip: 'Copy All',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.blue),
              onPressed: () => _shareLogs(),
              tooltip: 'Share Logs',
            ),
          ],
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            onPressed: () => _logger.clear(),
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: _logger.logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No logs captured yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groupedLogs.length,
              itemBuilder: (context, index) {
                final contextId = groupedLogs.keys.elementAt(index);
                final entries = groupedLogs[contextId]!;
                return _LogGroup(
                  contextId: contextId,
                  entries: entries,
                  onShare: () => _shareLogs(contextId: contextId),
                  onCopy: () => _copyLogs(contextId: contextId),
                );
              },
            ),
    );
  }
}

class _LogGroup extends StatelessWidget {
  final String contextId;
  final List<LogEntry> entries;
  final VoidCallback onShare;
  final VoidCallback onCopy;

  const _LogGroup({
    required this.contextId,
    required this.entries,
    required this.onShare,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isSystem = contextId == "SYSTEM EVENTS";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          child: Row(
            children: [
              Icon(
                isSystem ? Icons.settings_suggest : Icons.play_circle_fill,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  contextId.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.blue),
                onPressed: onCopy,
                tooltip: 'Copy Group',
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.share_outlined, size: 16, color: Colors.blue),
                onPressed: onShare,
                tooltip: 'Share Group',
              ),
            ],
          ),
        ),
        ...entries.map((e) => _LogEntryCard(entry: e)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final LogEntry entry;

  const _LogEntryCard({required this.entry});

  Color _getLevelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red[700]!;
      case LogLevel.warning:
        return Colors.orange[800]!;
      case LogLevel.info:
        return Colors.blue[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getLevelColor(entry.level);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: color.withOpacity(0.05)),
      ),
      child: ExpansionTile(
        dense: true,
        leading: Icon(
          entry.level == LogLevel.error
              ? Icons.error_outline
              : (entry.level == LogLevel.warning
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline),
          color: color,
          size: 20,
        ),
        title: Text(
          entry.message,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          "${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}",
          style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
        ),
        childrenPadding: const EdgeInsets.all(12),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.technicalDetails != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: SelectableText(
                entry.technicalDetails!,
                style: GoogleFonts.shareTechMono(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: entry.technicalDetails!),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Details copied to clipboard'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('COPY DETAILS'),
              ),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text("No additional technical details.", style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
            ),
        ],
      ),
    );
  }
}
