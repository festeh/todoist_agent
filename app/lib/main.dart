import 'package:flutter/material.dart';
import 'ai_flow.dart';
import 'package:flutter/services.dart';

class PressButtonIntent extends Intent {
  const PressButtonIntent();
}

class PressButtonAction extends Action<PressButtonIntent> {
  PressButtonAction(this.callback);

  final VoidCallback callback;

  @override
  Object? invoke(PressButtonIntent intent) {
    callback();
    return null;
  }
}

void main() {
  runApp(const MyApp()); // Run the root App widget
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
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
  // Method to update the status when the button is pressed
  void _pressButton() {
    setState(() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AiFlow()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(title: Center()),
      // Use FloatingActionButton for the bottom-right button
      floatingActionButton: FloatingActionButton(
        onPressed: _pressButton,
        tooltip: 'Press Me',
        child: const Icon(Icons.mic), // Microphone icon
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
