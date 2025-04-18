import 'package:intl/intl.dart';

/// Logs a message to stdout with a timestamp.
///
/// Example: [2025-04-18 10:30:00.123] Your log message here
void log(String message) {
  final now = DateTime.now();
  // Ensure you add the intl package dependency in pubspec.yaml
  final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(now);
  print('[$formattedTimestamp] $message');
}
