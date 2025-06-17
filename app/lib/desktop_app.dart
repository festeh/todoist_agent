import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
class DesktopApp extends StatelessWidget {
  const DesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: const Home(),
    );
  }
}

// Main page widget for the standard application
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

// State for the main page
class _HomeState extends State<Home> {
  final TextEditingController _textController = TextEditingController();
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _loadMutePreference();
  }

  Future<void> _loadMutePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isMuted = prefs.getBool('isMuted') ?? false;
    });
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isMuted', _isMuted);
  }

  void _navigateToAiFlowRecording() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AiFlow(startRecordingOnInit: true, isMuted: _isMuted),
      ),
    );
  }

  void _navigateToAiFlowWithText(String text) {
    if (text.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiFlow(
            initialText: text, startRecordingOnInit: false, isMuted: _isMuted),
      ),
    );
    _textController.clear();
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
        title: const Center(child: Text("Todoist Agent")),
        actions: [
          IconButton(
            icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up),
            onPressed: _toggleMute,
            tooltip: 'Mute/Unmute',
          ),
        ],
      ),
      body: const Center(child: Text("")),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _navigateToAiFlowWithText,
                decoration: InputDecoration(
                  hintText: 'Enter Task here or press Mic...',
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
