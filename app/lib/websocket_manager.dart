import 'dart:async';
import 'dart:convert'; // Import for jsonEncode
import 'dart:typed_data'; // Import for Uint8List
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart'; // Keep for debugPrint or potential UI interaction

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketManager {
  WebSocketChannel? _channel;
  final String _url;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _errorMessage = '';

  // Stream controllers to broadcast status changes
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  WebSocketManager(this._url);

  // Getters for current status
  ConnectionStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Stream getters
  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;
  Stream<String> get onError => _errorController.stream;

  Future<void> connect() async {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      // Listen for connection events
      _channel!.stream.listen(
        (message) {
          // Handle incoming messages
          debugPrint('WebSocket message: $message');
        },
        onDone: () {
          _updateStatus(ConnectionStatus.disconnected);
          debugPrint('WebSocket connection closed');
        },
        onError: (error) {
          _updateError('Connection error: $error');
          _updateStatus(ConnectionStatus.error);
          debugPrint('WebSocket error: $error');
        },
      );

      _updateStatus(ConnectionStatus.connected);
      debugPrint('WebSocket connected to $_url');
    } catch (e) {
      _updateError('Failed to connect: $e');
      _updateStatus(ConnectionStatus.error);
      debugPrint('WebSocket connection failed: $e');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _updateStatus(ConnectionStatus.disconnected);
  }

  bool send(dynamic data) {
    if (_status != ConnectionStatus.connected) {
      return false;
    }

    try {
      _channel?.sink.add(data);
      return true;
    } catch (e) {
      _updateError('Failed to send data: $e');
      return false;
    }
  }

  /// Sends audio data in chunks over the WebSocket.
  ///
  /// Sends a START_AUDIO message, then chunks the [audioBytes] into 1MB segments
  /// sending each as a {"bytes": [chunk]} message, and finally sends an END_AUDIO message.
  /// Returns true if all messages were sent successfully, false otherwise.
  Future<bool> sendAudio(Uint8List audioBytes) async {
    if (_status != ConnectionStatus.connected) {
      debugPrint('WebSocket not connected. Cannot send audio.');
      _updateError('Attempted to send audio while disconnected.');
      return false;
    }

    const int chunkSize = 1024 * 1024; // 1MB chunk size

    try {
      // 1. Send START_AUDIO message
      final startMessage = jsonEncode({'text': 'START_AUDIO'});
      _channel?.sink.add(startMessage);
      debugPrint('Sent START_AUDIO marker.');

      // 2. Send audio data in chunks
      for (int i = 0; i < audioBytes.length; i += chunkSize) {
        final end = (i + chunkSize < audioBytes.length) ? i + chunkSize : audioBytes.length;
        // Create a sublist view, then convert to List<int> for JSON encoding
        final chunk = audioBytes.sublist(i, end).toList();
        final chunkMessage = jsonEncode({'bytes': chunk});
        _channel?.sink.add(chunkMessage);
        // Optional: Add a small delay if needed for flow control, though TCP should handle it.
        // await Future.delayed(Duration(milliseconds: 10));
        debugPrint('Sent audio chunk: ${i ~/ chunkSize + 1}');
      }

      // 3. Send END_AUDIO message
      final endMessage = jsonEncode({'text': 'END_AUDIO'});
      _channel?.sink.add(endMessage);
      debugPrint('Sent END_AUDIO marker.');

      return true; // Indicate success
    } catch (e) {
      final errorMessage = 'Failed during audio send process: $e';
      _updateError(errorMessage);
      debugPrint(errorMessage);
      // Attempt to send END_AUDIO even on error? Depends on server requirements.
      // try {
      //   final endMessage = jsonEncode({'text': 'END_AUDIO'});
      //   _channel?.sink.add(endMessage);
      // } catch (_) {} // Ignore error during cleanup send
      return false; // Indicate failure
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

  void dispose() {
    disconnect();
    _statusController.close();
    _errorController.close();
  }
}
