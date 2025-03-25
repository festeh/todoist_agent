import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

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
  bool _isTimerRunning = false;
  int _seconds = 0;
  late DateTime _startTime;

  void _handleButtonPress() {
    log.info('Button pressed');
    setState(() {
      if (_isTimerRunning) {
        // Stop the timer
        _isTimerRunning = false;
        _seconds = 0;
      } else {
        // Start the timer
        _isTimerRunning = true;
        _startTime = DateTime.now();
        _startTimer();
      }
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_isTimerRunning) {
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
              Positioned(
                top: screenWidth * 0.3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isTimerRunning ? '$_seconds' : '',
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
                    padding: EdgeInsets.all(screenWidth * 0.08), // Smaller button
                    backgroundColor: Colors.blue,
                  ),
                  child: Icon(
                    _isTimerRunning ? Icons.stop : Icons.play_arrow,
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
