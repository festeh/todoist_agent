import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger log = Logger('WearApp');

void main() {
  Logger.root.level = Level.ALL;
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

class WearHomePage extends StatelessWidget {
  const WearHomePage({super.key});

  void _handleButtonPress() {
    log.info('Button pressed');
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
          child: ElevatedButton(
            onPressed: _handleButtonPress,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.all(screenWidth * 0.1),
              backgroundColor: Colors.blue,
            ),
            child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
          ),
        ),
      ),
    );
  }
}
