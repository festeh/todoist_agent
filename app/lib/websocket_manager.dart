import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

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
