import 'dart:async';
import 'dart:convert'; // Import for jsonEncode
import 'dart:typed_data'; // Import for Uint8List
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart'; // Keep for debugPrint or potential UI interaction

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketManager {
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  final String _url;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _errorMessage = '';

  // Stream controllers to broadcast changes
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _asrMessageController =
      StreamController<String>.broadcast(); // For ASR messages

  WebSocketManager(this._url);

  // Getters for current status
  ConnectionStatus get status => _status;
  String get errorMessage => _errorMessage;

  // Stream getters
  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onAsrMessage =>
      _asrMessageController.stream; // Public stream for ASR

  Future<void> connect() async {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      _channelSubscription = _channel!.stream.listen(
        (message) {
          debugPrint('Raw WebSocket message: $message');
          final decoded = jsonDecode(message);
          if (decoded['type'] == 'asr' && decoded.containsKey('message')) {
            final asrText = decoded['message'] as String;
            _asrMessageController.add(asrText);
            debugPrint('Received ASR message: $asrText');
          } else {
            debugPrint('Received other JSON message: $decoded');
          }
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

  Future<void> disconnect() async {
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
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

  Future<bool> sendTranscription(String text) async {
    if (_status != ConnectionStatus.connected) {
      debugPrint('WebSocket not connected. Cannot send text.');
      _updateError('Attempted to send text while disconnected.');
      return false;
    }

    try {
      _channel?.sink.add(jsonEncode({'type': 'transcription', 'message': text}));
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
    _asrMessageController.close();
  }
}
