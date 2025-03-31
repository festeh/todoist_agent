import 'package:flutter/material.dart';
import 'second_screen.dart';
import 'package:flutter/services.dart';

// Define the possible states for the application status
enum AppStatus { idle, pressed }

class PressButtonIntent extends Intent {
  const PressButtonIntent();
}

// Define an Action that calls the _pressButton callback
class PressButtonAction extends Action<PressButtonIntent> {
  PressButtonAction(this.callback);

  final VoidCallback callback;

  @override
  Object? invoke(PressButtonIntent intent) {
    callback();
    // Return null because the action doesn't produce a result.
    return null;
  }
}

void main() {
  runApp(const MyApp()); // Run the root App widget
}

// Root application widget that sets up MaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: false,
      home: MyHomePage(), // Set MyHomePage as the initial route
    );
  }
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SecondScreen()),
      );
    });
  }

  // Helper to get the string representation of the status
  String _getStatusText() {
    switch (_status) {
      case AppStatus.idle:
        return 'Idle';
      case AppStatus.pressed:
        return 'Pressed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: Center(
          // Display the status indicator in the center of the AppBar
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              // Use a background color for the oval
              color: Colors.blueGrey[700], // Example color
              // Make it oval/pill-shaped
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              _getStatusText(),
              // Ensure text is visible on the background
              style: const TextStyle(color: Colors.white),
            ),
          ),
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
      ),
    );
    final isLinux = Theme.of(context).platform == TargetPlatform.linux;
    if (isLinux) {
      final shortcuts = <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.keyS): const PressButtonIntent(),
      };

      final actions = <Type, Action<Intent>>{
        PressButtonIntent: PressButtonAction(_pressButton),
      };

      return Actions(
        actions: actions,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Focus(autofocus: true, child: scaffold),
        ),
      );
    }
    return scaffold;
  }
}
