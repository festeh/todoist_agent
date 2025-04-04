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

  Future<bool> sendAudio(Uint8List audioBytes) async {
    if (_status != ConnectionStatus.connected) {
      debugPrint('WebSocket not connected. Cannot send audio.');
      _updateError('Attempted to send audio while disconnected.');
      return false;
    }

    const int chunkSize = 1024 * 1024; // 1MB chunk size

    try {
      _channel?.sink.add("START_AUDIO");
      debugPrint('Sent START_AUDIO marker.');

      for (int i = 0; i < audioBytes.length; i += chunkSize) {
        final end =
            (i + chunkSize < audioBytes.length)
                ? i + chunkSize
                : audioBytes.length;
        final chunk = audioBytes.sublist(i, end).toList();
        // final chunkMessage = jsonEncode({'bytes': chunk});
        _channel?.sink.add(chunk);
      }

      _channel?.sink.add("END_AUDIO");
      debugPrint('Sent END_AUDIO marker.');

      return true; // Indicate success
    } catch (e) {
      final errorMessage = 'Failed during audio send process: $e';
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

  void dispose() {
    disconnect();
    _statusController.close();
    _errorController.close();
  }
}
