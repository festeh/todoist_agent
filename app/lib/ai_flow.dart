import 'package:flutter/material.dart';
import 'dart:async'; // Import async library for Timer

class AiFlow extends StatefulWidget {
  const AiFlow({super.key});

  @override
  State<AiFlow> createState() => _AiFlowState();
}

class _AiFlowState extends State<AiFlow> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsedTime = _formatTime(0);

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {
          _elapsedTime = _formatTime(_stopwatch.elapsedMilliseconds);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer to avoid memory leaks
    _stopwatch.stop();
    super.dispose();
  }

  static String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate();
    String secondsStr = seconds.toString().padLeft(2, '0');
    return secondsStr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Flow'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Display the timer
            Text(
              _elapsedTime,
              style:
                  Theme.of(
                    context,
                  ).textTheme.headlineMedium, // Make text larger
            ),
            const SizedBox(height: 20), // Add some space
            // Done button
            ElevatedButton(
              onPressed: () {
                _stopwatch.stop();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
