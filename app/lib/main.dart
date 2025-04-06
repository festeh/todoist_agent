import 'package:flutter/material.dart';
import 'ai_flow.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

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
    return MaterialApp(
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

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
        builder: (context) => AiFlow(
          initialText: text,
          startRecordingOnInit: false,
        ),
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
                    ), // Increased radius for more rounded corners
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 8,
            ), // Add spacing between text field and button
            FloatingActionButton(
              onPressed: _navigateToAiFlowRecording, // Use specific method for mic
              tooltip: 'Start Recording',
              child: const Icon(Icons.mic),
            ),
          ],
        ),
      ),
    );
    final isLinux = Theme.of(context).platform == TargetPlatform.linux;
    if (isLinux) {
      final shortcuts = <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.keyS): const PressButtonIntent(),
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
