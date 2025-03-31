import 'package:flutter/material.dart';
import 'dart:async'; // Import async library for Timer

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  State<SecondScreen> createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsedTime = _formatTime(0);

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    // Update the UI every 50 milliseconds
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
        title: const Text('Timer Screen'),
        // The AppBar automatically includes a back button
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
                _stopwatch.stop(); // Stop the timer
                Navigator.pop(context); // Go back to the previous screen
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
