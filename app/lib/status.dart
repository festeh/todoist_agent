import 'package:flutter/material.dart';

enum AppStatus { idle, recording }  

class StatusView extends StatelessWidget {
  const StatusView({super.key, required this.status});

  final AppStatus status;

  String _getStatusText() {
    switch (status) {
      case AppStatus.idle:
        return 'Idle';
      case AppStatus.recording:
        return 'Recording';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      decoration: BoxDecoration(
        color: Colors.limeAccent[700], 
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        _getStatusText(),
        // Ensure text is visible on the background
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
