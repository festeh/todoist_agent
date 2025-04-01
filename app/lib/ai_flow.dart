import 'dart:async';
import 'package:flutter/material.dart';
import 'audio_recorder.dart'; // Import the recorder service

class AiFlow extends StatefulWidget {
  const AiFlow({super.key});

  @override
  State<AiFlow> createState() => _AiFlowState();
}

class _AiFlowState extends State<AiFlow> {
  final Stopwatch _stopwatch = Stopwatch();
  late Timer _timer;
  String _elapsedTime = _formatTime(0);
  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  bool _isRecording = false; // Track recording state

  @override
  void initState() {
    super.initState();
    _startTimerAndRecording();
  }

  Future<void> _startTimerAndRecording() async {
    // Start stopwatch and timer
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_stopwatch.isRunning) {
        setState(() {
          _elapsedTime = _formatTime(_stopwatch.elapsedMilliseconds);
        });
      }
    });

    // Start recording
    await _audioRecorderService.startRecording();
    setState(() {
      _isRecording = true; // Update state after attempting to start
    });
  }

  Future<void> _stopTimerAndRecording() async {
    _timer.cancel();
    _stopwatch.stop();
    if (_isRecording) {
      await _audioRecorderService.stopRecording();
      setState(() {
        _isRecording = false;
      });
    }
  }

  @override
  void dispose() {
    _stopTimerAndRecording(); // Ensure recording is stopped
    _audioRecorderService.dispose(); // Dispose the recorder resources
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
            // Stop button
            ElevatedButton(
              onPressed: _isRecording ? _stopTimerAndRecording : null, // Only enable if recording
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: const RoundedRectangleBorder( // Explicitly rectangular
                  borderRadius: BorderRadius.zero, // Or a small radius if preferred
                ),
              ),
              child: const Text('Stop'),
            ),
            const SizedBox(height: 20), // Add some space between buttons
            // Done button
            ElevatedButton(
              onPressed: () async {
                await _stopTimerAndRecording();
                if (mounted) { // Check if the widget is still in the tree
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}
