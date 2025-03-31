import 'package:flutter/material.dart';

// Define the possible states for the application status
enum AppStatus { idle, pressed }

void main() {
  runApp(const MyHomePage());
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // State variable to hold the current status
  AppStatus _status = AppStatus.idle;

  // Method to update the status when the button is pressed
  void _pressButton() {
    setState(() {
      _status = AppStatus.pressed;
    });
  }

  // Helper to get the string representation of the status
  String _getStatusText() {
    switch (_status) {
      case AppStatus.idle:
        return 'IDLE';
      case AppStatus.pressed:
        return 'PRESSED';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Center(
            // Display the status indicator in the center of the AppBar
            child: Text('Status: ${_getStatusText()}'),
          ),
        ),
        // Use FloatingActionButton for the bottom-right button
        floatingActionButton: FloatingActionButton(
          onPressed: _pressButton,
          tooltip: 'Press Me',
          child: const Icon(Icons.add), // Example icon
        ),
        // Ensure the button is positioned at the bottom right
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: const Center(
          // Placeholder for main content, can be removed or replaced later
          child: Text('Main Content Area'),
        ),
      ),
    );
  }
}
