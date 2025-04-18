import 'package:intl/intl.dart';

void log(String message) {
  final now = DateTime.now();
  final formattedTimestamp = DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(now);
  print('[$formattedTimestamp] $message');
}
