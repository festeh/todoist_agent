import 'dart:io'; // Import for File operations
import 'dart:typed_data'; // Import for Uint8List
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  Future<bool> hasPermission() async {
    return await _audioRecorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (!await hasPermission()) {
      debugPrint("Recording permission not granted.");
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      // Consider using a more robust naming scheme (e.g., timestamp)
      _recordingPath = '${directory.path}/recording.ogg';

      const config = RecordConfig(
        encoder: AudioEncoder.opus,
        sampleRate: 16000,
        numChannels: 1,
        noiseSuppress: true,
        autoGain: true,
        bitRate: 16000,
      );

      // Start recording to file
      await _audioRecorder.start(config, path: _recordingPath!);
      debugPrint("Recording started: $_recordingPath");
    } catch (e) {
      debugPrint("Error starting recording: $e");
      _recordingPath = null; // Reset path on error
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      debugPrint("Recording stopped: $path");
      _recordingPath = path;
      return _recordingPath;
    } catch (e) {
      debugPrint("Error stopping recording: $e");
      return null;
    } finally {
      // dispose(); // Consider if dispose should be called here or elsewhere
    }
  }

  Future<void> dispose() async {
    await _audioRecorder.dispose();
    debugPrint("Audio recorder disposed.");
  }

  bool isRecording() {
    // Note: The record package doesn't have a synchronous isRecording status check
    // in the latest versions. You might need to manage state externally
    // based on start/stop calls if precise synchronous status is needed.
    // For now, we can infer based on whether stopRecording has been called successfully.
    return _recordingPath !=
        null; // Simplistic check, assumes path is set only during recording
  }

  /// Reads the recorded audio file and returns its content as bytes.
  /// Returns null if the recording path is not set or the file doesn't exist.
  Future<Uint8List?> getRecordedBytes() async {
    if (_recordingPath == null) {
      debugPrint("Recording path is not set.");
      return null;
    }

    final file = File(_recordingPath!);
    if (!await file.exists()) {
      debugPrint("Recorded file does not exist: $_recordingPath");
      return null;
    }

    try {
      final bytes = await file.readAsBytes();
      debugPrint("Read ${bytes.length} bytes from $_recordingPath");
      return bytes;
    } catch (e) {
      debugPrint("Error reading recorded file: $e");
      return null;
    }
  }
}
