import 'dart:io'; // Import for File operations
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

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
        // bitRate: 16000,
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

  Future<Uint8List?> getRecordedBytes() async {
    if (_recordingPath == null) {
      debugPrint("Recording path is not set.");
      return null;
    }
    const maxRetries = 20;
    const retryDelay = Duration(milliseconds: 50);
    bool fileExists = false;
    var file = File(_recordingPath!);

    for (int i = 0; i < maxRetries; i++) {
      if (await file.exists()) {
        fileExists = true;
        debugPrint("File found after $i attempt(s).");
        break;
      }
      await Future.delayed(retryDelay);
      file = File(_recordingPath!);
    }

    if (!fileExists) {
      debugPrint("File not found");
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
