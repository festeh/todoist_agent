import 'dart:io' show Platform; // Import Platform
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import kIsWeb for web check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import PlatformException
import 'package:wear/wear.dart'; // Import wear package
import 'standard_app.dart'; // Import the standard app UI

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
    // Using MaterialApp to provide basic structure and theme handling.
    // You might want to customize the theme specifically for Wear OS later.
    return const MaterialApp(
      home: Scaffold(
        // Using a simple Scaffold for structure
        body: Center(
          child: Text('Wear OS App Placeholder'), // Placeholder text
        ),
      ),
      debugShowCheckedModeBanner: false, // Optional: hide debug banner
    );
  }
}
