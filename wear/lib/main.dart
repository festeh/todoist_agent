import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final Logger log = Logger('WearApp');

void main() {
  // Initialize logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: const WearHomePage(),
    );
  }
}

class WearHomePage extends StatefulWidget {
  const WearHomePage({super.key});

  @override
  State<WearHomePage> createState() => _WearHomePageState();
}

class _WearHomePageState extends State<WearHomePage> {
  bool _isRecording = false;
  int _seconds = 0;
  late DateTime _startTime;
  final _audioRecorder = AudioRecorder();
  String _recordingInfo = '';

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      log.warning('Microphone permission not granted');
    } else {
      log.info('Microphone permission granted');
    }
  }

  Future<void> _handleButtonPress() async {
    log.info('Button pressed');

    if (_isRecording) {
      final path = await _audioRecorder.stop();

      setState(() {
        if (path != null) {
          final file = File(path);
          final fileSize = file.lengthSync();
          _recordingInfo =
              'Recording saved: ${file.path}\n'
              'Size: ${(fileSize / 1024).toStringAsFixed(2)} KB\n'
              'Duration: $_seconds seconds';
          log.info(_recordingInfo);
        }

        _seconds = 0;
        _isRecording = false;
      });
    } else {
      // Start recording
      try {
        // Get temporary directory for storing the recording
        final tempDir = await getTemporaryDirectory();
        final recordingPath = '${tempDir.path}/recording.m4a';

        // Configure recording
        final config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 16000,
        );

        // Start recording
        await _audioRecorder.start(config, path: recordingPath);

        setState(() {
          _isRecording = true;
          _startTime = DateTime.now();
          _recordingInfo = '';
          _startTimer();
        });

        log.info('Recording started at: $recordingPath');
      } catch (e) {
        log.severe('Error starting recording: $e');
      }
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isRecording) {
        setState(() {
          _seconds = DateTime.now().difference(_startTime).inSeconds;
        });
        _startTimer(); // Continue the timer
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen size to ensure our UI works well on round displays
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        // Use BoxDecoration to create a circular container
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Timer display
              Text(
                _recordingInfo,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              Positioned(
                top: screenWidth * 0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$_seconds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Button positioned lower on the screen
              Positioned(
                top: screenWidth * 0.5, // Move button down
                child: ElevatedButton(
                  onPressed: _handleButtonPress,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: EdgeInsets.all(
                      screenWidth * 0.08,
                    ), // Smaller button
                    backgroundColor: Colors.blue,
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 30, // Slightly smaller icon
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
