import 'dart:async';
import 'package:flutter/material.dart';
import 'audio_recorder.dart';
import 'websocket_manager.dart';

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

  late WebSocketManager _webSocketManager;

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String _connectionError = '';
  String _asrMessage = ''; // State variable for ASR text

  @override
  void initState() {
    super.initState();
    _startTimerAndRecording();
    _initWebSocket();
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
  }

  void _initWebSocket() {
    final websocketUrl = const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: 'ws://localhost:8000/connect',
    );

    _webSocketManager = WebSocketManager(websocketUrl);

    _webSocketManager.onStatusChange.listen((status) {
      if (!mounted) return;
      setState(() {
        debugPrint('WebSocket status changed: $status');
        _connectionStatus = ConnectionStatus.connected;
      });
    });

    _webSocketManager.onAsrMessage.listen((message) {
      if (!mounted) return;
      setState(() {
        _asrMessage = message;
        debugPrint('UI updated with ASR: $message');
      });
    });

    _webSocketManager.onError.listen((error) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.error;
        _connectionError = error;
      });
    });

    _webSocketManager.connect();
  }

  Future<void> _stopTimerAndRecording() async {
    _timer.cancel();
    _stopwatch.stop();
    final recordingPath = await _audioRecorderService.stopRecording();

    if (recordingPath == null) {
      debugPrint("stopRecording returned null, cannot proceed.");
      return;
    }

    final recorded = await _audioRecorderService.getRecordedBytes();
    if (recorded != null) {
      _webSocketManager.sendAudio(recorded);
    }
  }

  @override
  void dispose() {
    _stopTimerAndRecording();
    _audioRecorderService.dispose();
    _webSocketManager.dispose();
    super.dispose();
  }

  static String _formatTime(int milliseconds) {
    int seconds = (milliseconds / 1000).truncate();
    String secondsStr = seconds.toString().padLeft(2, '0');
    return secondsStr;
  }

  Widget _buildConnectionStatusWidget() {
    Color statusColor;
    String statusText;

    switch (_connectionStatus) {
      case ConnectionStatus.disconnected:
        statusColor = Colors.grey;
        statusText = 'Disconnected';
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusText = 'Connected';
        break;
      case ConnectionStatus.error:
        statusColor = Colors.red;
        statusText = 'Error: $_connectionError';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: statusColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _connectionStatus == ConnectionStatus.connected
                ? Icons.check_circle
                : _connectionStatus == ConnectionStatus.connecting
                ? Icons.sync
                : _connectionStatus == ConnectionStatus.error
                ? Icons.error
                : Icons.offline_bolt,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(statusText, style: TextStyle(color: statusColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Flow')),
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
              onPressed: _stopTimerAndRecording,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.zero, // Or a small radius if preferred
                ),
              ),
              child: const Text('Stop'),
            ),
            const SizedBox(height: 20), // Add some space
            _buildConnectionStatusWidget(),
            const SizedBox(height: 20), // Add space before ASR text
            // Display the ASR message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _asrMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
