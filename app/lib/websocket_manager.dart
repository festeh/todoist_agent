import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Use dart:io for WebSocket
import 'dart:typed_data'; // Import for Uint8List
import 'package:flutter/foundation.dart'; // Use foundation for debugPrint

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketManager {
  WebSocket? _channel; // Changed type to dart:io WebSocket
  StreamSubscription? _channelSubscription;
  final String _url;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _errorMessage = '';

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _messageController = StreamController<String>.broadcast();
  final _audioController = StreamController<Uint8List>.broadcast(); // Controller for audio bytes

  WebSocketManager(this._url);

  // Getters for current status
  ConnectionStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Stream getters
  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onMessage => _messageController.stream;
  Stream<Uint8List> get onAudioReceived => _audioController.stream; // Stream for audio bytes

  Future<void> connect() async {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    // Retrieve the access key from environment variables
    const String agentAccessKey = String.fromEnvironment(
      'TODOIST_AGENT_ACCESS_KEY',
      defaultValue: '',
    );

    if (agentAccessKey.isEmpty) {
      _updateError('Access key not found');
      _updateStatus(ConnectionStatus.error);
    }

    final Map<String, dynamic> headers = {'X-Agent-Access-Key': agentAccessKey};

    try {
      _channel = await WebSocket.connect(_url, headers: headers);

      _updateStatus(ConnectionStatus.connected);
      debugPrint('WebSocket connected to $_url');

      // Listen for messages, errors, and closure
      _channelSubscription = _channel!.listen(
        (message) {
          // Check if the message is binary data (Uint8List)
          if (message is Uint8List) {
            debugPrint('Received binary data (assuming MP3), length: ${message.length}');
            _audioController.add(message); // Add binary data to the audio stream
          } else if (message is String) {
            // Handle text messages (existing logic)
            try {
              final decoded = jsonDecode(message);
              if (decoded.containsKey('message')) {
                _messageController.add(decoded['message']);
              }
              // Example: Handle specific text message types if needed
              // if (decoded['type'] == 'asr' && decoded.containsKey('message')) {
              //   final asrText = decoded['message'] as String;
              //   _messageController.add(asrText); // Or use a dedicated stream if preferred
              //   debugPrint('Received ASR message: $asrText');
              // } else {
              //   debugPrint('Received other JSON message: $decoded');
              // }
            } catch (e) {
              debugPrint('Error decoding JSON message: $e');
              // Handle non-JSON string messages if necessary
              // _messageController.add(message); // Example: pass raw string
            }
          } else {
            // Handle other unexpected message types
            debugPrint('Received unexpected message type: ${message.runtimeType}');
          }
        },
        onError: (error) {
          _updateError('WebSocket error: $error');
          _updateStatus(ConnectionStatus.error);
          debugPrint('WebSocket error: $error');
          // Consider attempting reconnection or other error handling
        },
        onDone: () {
          _updateStatus(ConnectionStatus.disconnected);
          debugPrint('WebSocket connection closed by server.');
          // Clean up resources if needed, or attempt reconnection
          _channel = null; // Ensure channel is nullified on closure
          _channelSubscription?.cancel();
          _channelSubscription = null;
        },
        cancelOnError: true, // Close the stream on error
      );
    } catch (e) {
      _updateError('Failed to connect to WebSocket: $e');
      _updateStatus(ConnectionStatus.error);
      debugPrint('WebSocket connection failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _channelSubscription?.cancel(); // Cancel the listener first
    _channelSubscription = null;
    await _channel?.close(); // Close the WebSocket connection
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected); // Update status after closing
    debugPrint('WebSocket disconnected.');
  }

  bool send(dynamic data) {
    if (_status != ConnectionStatus.connected) {
      return false;
    }

    try {
      _channel?.add(data); // Use add() directly on WebSocket
      return true;
    } catch (e) {
      _updateError('Failed to send data: $e');
      return false;
    }
  }

  Future<bool> sendAudio(Uint8List audioBytes) async {
    if (_status != ConnectionStatus.connected) {
      debugPrint('WebSocket not connected. Cannot send audio.');
      _updateError('Attempted to send audio while disconnected.');
      return false;
    }

    try {
      _channel?.add("START_AUDIO");
      debugPrint('Sent START_AUDIO marker.');

      _channel?.add(audioBytes);

      _channel?.add("END_AUDIO");
      debugPrint('Sent END_AUDIO marker.');

      return true;
    } catch (e) {
      final errorMessage = 'Failed during audio send process: $e';
      _updateError(errorMessage);
      debugPrint(errorMessage);
      return false;
    }
  }

  Future<bool> sendTranscription(String text) async {
    if (_status != ConnectionStatus.connected) {
      debugPrint('WebSocket not connected. Cannot send text.');
      _updateError('Attempted to send text while disconnected.');
      return false;
    }

    try {
      _channel?.add(
        jsonEncode({'type': 'transcription', 'message': text}),
      );
      debugPrint('Sent transcription: $text');
      return true;
    } catch (e) {
      final errorMessage = 'Failed during text send process: $e';
      _updateError(errorMessage);
      debugPrint(errorMessage);
      return false;
    }
  }

  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  void _updateError(String message) {
    _errorMessage = message;
    _errorController.add(message);
  }

  void dispose() async {
    await disconnect();
    await disconnect(); // Ensure disconnect is called before closing controllers
    _statusController.close();
    _errorController.close();
    _messageController.close();
    _audioController.close(); // Close the audio controller
  }
}
