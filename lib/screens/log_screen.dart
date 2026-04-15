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

  void _shareLogs() {
    final logs = _logger.logs;
    if (logs.isEmpty) return;

    final String logText = logs.map((e) {
      return "[${e.timestamp}] ${e.level.name.toUpperCase()}: ${e.message}\n"
             "${e.technicalDetails != null ? 'Details: ${e.technicalDetails}\n' : ''}";
    }).join('\n---\n');

    Share.share(
      logText,
      subject: 'GastRotator System Logs - ${DateTime.now()}',
    );
  }

  void _copyAllLogs() {
    final logs = _logger.logs;
    if (logs.isEmpty) return;

    final String logText = logs.map((e) {
      return "[${e.timestamp}] ${e.level.name.toUpperCase()}: ${e.message}\n"
             "${e.technicalDetails != null ? 'Details: ${e.technicalDetails}\n' : ''}";
    }).join('\n---\n');

    Clipboard.setData(ClipboardData(text: logText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All logs copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logs = _logger.logs;

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
          if (logs.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.copy_all_rounded, color: Colors.blue),
              onPressed: _copyAllLogs,
              tooltip: 'Copy All',
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.blue),
              onPressed: _shareLogs,
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
      body: logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No logs captured yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = logs[index];
                return _LogEntryCard(entry: entry);
              },
            ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.1)),
      ),
      child: ExpansionTile(
        leading: Icon(
          entry.level == LogLevel.error 
              ? Icons.error_outline 
              : (entry.level == LogLevel.warning ? Icons.warning_amber_rounded : Icons.info_outline),
          color: color,
        ),
        title: Text(
          entry.message,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(
          "${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')} - ${entry.level.name.toUpperCase()}",
          style: theme.textTheme.labelSmall,
        ),
        childrenPadding: const EdgeInsets.all(16),
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
                  Clipboard.setData(ClipboardData(text: entry.technicalDetails!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Details copied to clipboard')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('COPY DETAILS'),
              ),
            ),
          ] else
            const Text("No additional technical details."),
        ],
      ),
    );
  }
}
