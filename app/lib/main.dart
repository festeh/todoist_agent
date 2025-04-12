import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wear/wear.dart';
import 'standard_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isWearOS = false;

  if (Platform.isAndroid) {
    try {
      await Wear.instance.setAutoResumeEnabled(false);

      isWearOS = true;
      debugPrint(
        "Detected Wear OS device via successful platform channel call.",
      );
    } on PlatformException catch (e) {
      debugPrint(
        "PlatformException caught, indicating not a Wear OS device: $e",
      );
      isWearOS = false;
    } catch (e) {
      debugPrint("Unexpected error during Wear OS detection on Android: $e");
      isWearOS = false;
    }
  }

  runApp(isWearOS ? const WearOsPlaceholder() : const MyApp());
}

class WearOsPlaceholder extends StatelessWidget {
  const WearOsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Wear OS App Placeholder'), // Placeholder text
        ),
      ),
      debugShowCheckedModeBanner: false, // Optional: hide debug banner
    );
  }
}
