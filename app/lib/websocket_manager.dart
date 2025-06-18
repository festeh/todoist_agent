import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'logger.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class WebSocketManager {
  WebSocket? _channel;
  StreamSubscription? _channelSubscription;
  final String _url;
  final bool _isMuted;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  String _errorMessage = '';

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _messageController = StreamController<String>.broadcast();
  final _audioController = StreamController<Uint8List>.broadcast();

  WebSocketManager(this._url, {required bool isMuted}) : _isMuted = isMuted;

  ConnectionStatus get status => _status;
  String get errorMessage => _errorMessage;

  Stream<ConnectionStatus> get onStatusChange => _statusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onMessage => _messageController.stream;
  Stream<Uint8List> get onAudioReceived => _audioController.stream;

  Future<void> connect() async {
    if (_status == ConnectionStatus.connected ||
        _status == ConnectionStatus.connecting) {
      return;
    }

    _updateStatus(ConnectionStatus.connecting);

    const String agentAccessKey = String.fromEnvironment(
      'TODOIST_AGENT_ACCESS_KEY',
      defaultValue: '',
    );

    if (agentAccessKey.isEmpty) {
      _updateError('Access key not found');
      _updateStatus(ConnectionStatus.error);
    }

    final Map<String, dynamic> headers = {
      'X-Agent-Access-Key': agentAccessKey,
      'X-Muted': _isMuted.toString(),
    };

    try {
      _channel = await WebSocket.connect(_url, headers: headers);

      _updateStatus(ConnectionStatus.connected);
      log('WebSocket connected to $_url');

      _channel?.add("INIT");

      // Listen for messages, errors, and closure
      _channelSubscription = _channel!.listen(
        (message) {
          // Log raw message arrival immediately
          log('Raw WebSocket data received. Type: ${message.runtimeType}');
          if (message is Uint8List) {
            log('Processing binary data, length: ${message.length}');
            _audioController.add(message);
          } else if (message is String) {
            log('Processing text message: $message'); // Renamed log for clarity
            try {
              final decoded = jsonDecode(message);
              if (decoded.containsKey('message')) {
                _messageController.add(decoded['message']);
              }
            } catch (e) {
              log('Error decoding JSON message: $e');
            }
          } else {
            log('Received unexpected message type: ${message.runtimeType}');
          }
        },
        onError: (error) {
          _updateError('WebSocket error: $error');
          _updateStatus(ConnectionStatus.error);
          log('WebSocket error: $error');
        },
        onDone: () {
          _updateStatus(ConnectionStatus.disconnected);
          log('WebSocket connection closed by server.');
          _channel = null;
          _channelSubscription?.cancel();
          _channelSubscription = null;
        },
        cancelOnError: true,
      );
    } catch (e) {
      _updateError('Failed to connect to WebSocket: $e');
      _updateStatus(ConnectionStatus.error);
      log('WebSocket connection failed: $e');
    }
  }

  Future<void> disconnect() async {
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    await _channel?.close();
    _channel = null;
    _updateStatus(ConnectionStatus.disconnected);
    log('WebSocket disconnected.');
  }

  bool send(dynamic data) {
    if (_status != ConnectionStatus.connected) {
      return false;
    }

    try {
      _channel?.add(data);
      return true;
    } catch (e) {
      _updateError('Failed to send data: $e');
      return false;
    }
  }

  Future<bool> sendAudio(Uint8List audioBytes) async {
    if (_status != ConnectionStatus.connected) {
      log('WebSocket not connected. Cannot send audio.');
      _updateError('Attempted to send audio while disconnected.');
      return false;
    }

    try {
      _channel?.add("START_AUDIO");
      log('Sent START_AUDIO marker.');

      _channel?.add(audioBytes);

      _channel?.add("END_AUDIO");
      log('Sent END_AUDIO marker.');

      return true;
    } catch (e) {
      final errorMessage = 'Failed during audio send process: $e';
      _updateError(errorMessage);
      log(errorMessage);
      return false;
    }
  }

  Future<bool> sendTranscription(String text) async {
    if (_status != ConnectionStatus.connected) {
      log('WebSocket not connected. Cannot send text.');
      _updateError('Attempted to send text while disconnected.');
      return false;
    }

    try {
      _channel?.add(jsonEncode({'type': 'transcription', 'message': text}));
      log('Sent transcription: $text');
      return true;
    } catch (e) {
      final errorMessage = 'Failed during text send process: $e';
      _updateError(errorMessage);
      log(errorMessage);
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
    _audioController.close();
  }
}
