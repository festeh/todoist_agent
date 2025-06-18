import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_recorder.dart';
import 'websocket_manager.dart';
import 'message_list_view.dart';
import 'logger.dart';
import 'timer_service.dart';

class AiFlow extends StatefulWidget {
  final String? initialText;
  final bool startRecordingOnInit;
  final bool isMuted;

  const AiFlow({
    super.key,
    this.initialText,
    required this.startRecordingOnInit,
    required this.isMuted,
  });

  @override
  State<AiFlow> createState() => _AiFlowState();
}

class _AiFlowState extends State<AiFlow> {
  final TimerService _timerService = TimerService();

  final AudioRecorderService _audioRecorderService = AudioRecorderService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  late WebSocketManager _webSocketManager;

  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String _connectionError = '';
  final List<String> _receivedMessages = [];
  bool _recording = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.startRecordingOnInit) {
      _startTimerAndRecording();
    } else {
      _recording = false;
    }
    _initWebSocket();
  }

  Future<void> _startTimerAndRecording() async {
    if (_recording) return;

    _timerService.startTimer();

    await _audioRecorderService.startRecording();
    setState(() {
      _recording = true;
    });
  }

  void _initWebSocket() {
    final websocketUrl = const String.fromEnvironment(
      'WEBSOCKET_URL',
      defaultValue: 'ws://localhost:8000/connect',
    );

    _webSocketManager = WebSocketManager(websocketUrl, isMuted: widget.isMuted);

    _webSocketManager.onStatusChange.listen((status) {
      if (!mounted) return;
      setState(() {
        log('WebSocket status changed: $status');
        _connectionStatus = status;

        if (status == ConnectionStatus.connected &&
            widget.initialText != null) {
          _webSocketManager.sendTranscription(widget.initialText!);
        }
      });
    });

    _webSocketManager.onMessage.listen((message) {
      if (!mounted) return;
      setState(() {
        _receivedMessages.add(message);
        log('UI received message: $message');
      });
    });

    _webSocketManager.onError.listen((error) {
      if (!mounted) return;
      setState(() {
        _connectionStatus = ConnectionStatus.error;
        _connectionError = error;
      });
    });

    _webSocketManager.onAudioReceived.listen((audioBytes) {
      if (!mounted) return;
      _playAudio(audioBytes);
    });

    _webSocketManager.connect();
  }

  void _stop() {
    _timerService.stopTimer();
    _recording = false;
  }

  Future<void> _stopTimerAndRecording() async {
    if (!_recording) return;

    _stop();
    final recordingPath = await _audioRecorderService.stopRecording();

    if (recordingPath == null) {
      log("stopRecording returned null, cannot proceed.");
      setState(() {
        _recording = false;
      });
      return;
    }

    final recorded = await _audioRecorderService.getRecordedBytes();
    if (recorded != null) {
      _webSocketManager.sendAudio(recorded);
    } else {
      log("Failed to get recorded bytes after stopping.");
    }
  }

  void _sendTextMessage() {
    if (_textController.text.isNotEmpty) {
      final message = _textController.text;
      _webSocketManager.sendTranscription(message);
      log('Sent message: $message');
      _textController.clear();
    }
  }

  @override
  void dispose() {
    _stop();
    _stop();
    _audioRecorderService.dispose();
    _webSocketManager.dispose();
    _audioPlayer.dispose();
    _timerService.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _playAudio(Uint8List audioBytes) async {
    try {
      await _audioPlayer.play(BytesSource(audioBytes));
      log("Playing received audio...");
    } catch (e) {
      log("Error playing audio: $e");
    }
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
        color: statusColor.withValues(alpha: 0.1),
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
            // Display the timer only when recording
            if (_recording)
              ValueListenableBuilder<String>(
                valueListenable: _timerService.elapsedTimeNotifier,
                builder: (context, value, child) {
                  return Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                },
              ),
            if (_recording) const SizedBox(height: 20),
            // Record/Stop button
            ElevatedButton(
              onPressed:
                  _recording ? _stopTimerAndRecording : _startTimerAndRecording,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.zero, 
                ),
              ),
              child: Text(_recording ? 'Stop' : 'Record'),
            ),
            const SizedBox(height: 20),
            _buildConnectionStatusWidget(),
            const SizedBox(height: 20),
            Expanded(child: MessageListView(messages: _receivedMessages)),
            _buildTextInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Enter a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _sendTextMessage,
          ),
        ],
      ),
    );
  }
}
