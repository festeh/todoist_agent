import 'dart:async';
import 'package:flutter/material.dart';

class TimerService {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final ValueNotifier<String> elapsedTimeNotifier =
      ValueNotifier<String>(_formatTime(0));

  static String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate();
    String secondsStr = seconds.toString().padLeft(2, '0');
    return secondsStr;
  }

  void startTimer() {
    if (_stopwatch.isRunning) {
      return;
    }
    _stopwatch.reset();
    elapsedTimeNotifier.value = _formatTime(0);
    _stopwatch.start();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_stopwatch.isRunning) {
        elapsedTimeNotifier.value =
            _formatTime(_stopwatch.elapsedMilliseconds);
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    _stopwatch.stop();
  }

  void dispose() {
    stopTimer();
    elapsedTimeNotifier.dispose();
  }
}
