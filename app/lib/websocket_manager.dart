import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Use dart:io for WebSocket
import 'dart:typed_data';
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

  WebSocketManager(this._url);

  // Getters for current status
  ConnectionStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Stream getters
  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onMessage => _messageController.stream;

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
      // Use WebSocket.connect from dart:io
      _channel = await WebSocket.connect(_url, headers: headers);

      _updateStatus(ConnectionStatus.connected);
      debugPrint('WebSocket connected to $_url');

      // Listen for messages, errors, and closure
      _channelSubscription = _channel!.listen(
        (message) {
          // Handle incoming messages (String or List<int>)
          if (message is String) {
            debugPrint('Raw WebSocket message (String): $message');
            try {
              final decoded = jsonDecode(message);
              if (decoded is Map && decoded.containsKey('message')) {
                _messageController.add(decoded['message']);
              }
            } catch (e) {
              debugPrint("Failed to decode JSON message: $e");
              // Handle non-JSON string messages if necessary
            }
          } else if (message is List<int>) {
            // Handle binary messages if needed
            debugPrint('Received binary message of length: ${message.length}');
          } else {
            debugPrint('Received unexpected message type: ${message.runtimeType}');
          }
          final decoded = jsonDecode(message);
          if (decoded.containsKey('message')) {
            _messageController.add(decoded['message']);
          }
          // if (decoded['type'] == 'asr' && decoded.containsKey('message')) {
          //   final asrText = decoded['message'] as String;
          //   _asrMessageController.add(asrText);
          //   debugPrint('Received ASR message: $asrText');
          // } else {
          //   debugPrint('Received other JSON message: $decoded');
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

    // dart:io WebSocket handles fragmentation, sending large data directly is often fine.
    // However, if explicit chunking is required by the server protocol:
    const int chunkSize = 1024 * 1024; // 1MB chunk size (adjust if needed)

    try {
      _channel?.add("START_AUDIO"); // Use add()
      debugPrint('Sent START_AUDIO marker.');

      // Send audio data (can send Uint8List directly)
      // If chunking is strictly necessary:
      /* for (int i = 0; i < audioBytes.length; i += chunkSize) {
        final end =
            (i + chunkSize < audioBytes.length)
                 ? i + chunkSize
                 : audioBytes.length;
         final chunk = audioBytes.sublist(i, end); // sublist creates Uint8List
         _channel?.add(chunk); // Use add()
       } */

      // Simpler approach: Send the whole byte list at once
      _channel?.add(audioBytes); // Use add()

      _channel?.add("END_AUDIO"); // Use add()
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
      _channel?.add( // Use add()
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
    _statusController.close();
    _errorController.close();
    _messageController.close();
  }
}
