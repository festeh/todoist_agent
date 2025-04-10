import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ai_flow.dart'; // Ensure AiFlow is imported
import 'theme.dart'; // Ensure theme is imported

// Intent for keyboard shortcut
class PressButtonIntent extends Intent {
  const PressButtonIntent();
}

// Action linked to the intent
class PressButtonAction extends Action<PressButtonIntent> {
  PressButtonAction(this.callback);

  final VoidCallback callback;

  @override
  Object? invoke(PressButtonIntent intent) {
    callback();
    return null;
  }
}

// Root widget for the standard application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const MyHomePage(),
    );
  }
}

// Main page widget for the standard application
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// State for the main page
class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _textController = TextEditingController();

  // Navigate to AiFlow, starting recording
  void _navigateToAiFlowRecording() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AiFlow(startRecordingOnInit: true),
      ),
    );
  }

  // Navigate to AiFlow with initial text, not starting recording
  void _navigateToAiFlowWithText(String text) {
    if (text.trim().isEmpty) return; // Don't navigate with empty text
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AiFlow(initialText: text, startRecordingOnInit: false),
      ),
    );
    _textController.clear(); // Clear text field after submission
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("My App")), // Added a title for context
      ),
      body: const Center(
        // Placeholder for main content, can be removed or replaced later
        child: Text("Main Content Area"),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _navigateToAiFlowWithText, // Handle submission
                decoration: InputDecoration(
                  hintText: 'Enter Task here or press Mic...', // Updated hint
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      20.0, // Increased radius for more rounded corners
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 8,
            ), // Add spacing between text field and button
            FloatingActionButton(
              onPressed:
                  _navigateToAiFlowRecording, // Use specific method for mic
              tooltip: 'Start Recording',
              child: const Icon(Icons.mic),
            ),
          ],
        ),
      ),
    );

    // Apply Linux-specific shortcuts if applicable
    final isLinux = Theme.of(context).platform == TargetPlatform.linux;
    if (isLinux) {
      final shortcuts = <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
            const PressButtonIntent(),
      };

      final actions = <Type, Action<Intent>>{
        // Ensure shortcut triggers the recording flow
        PressButtonIntent: PressButtonAction(_navigateToAiFlowRecording),
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
