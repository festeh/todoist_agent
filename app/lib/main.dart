import 'dart:io' show Platform; // Import Platform
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb for web check
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import PlatformException
import 'package:wear/wear.dart'; // Import wear package
import 'standard_app.dart'; // Import the standard app UI

void main() async {
  // Ensure Flutter bindings are initialized for async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();

  bool isWearOS = false;

  // Check if the platform is Android. Wear OS is based on Android.
  // Added kIsWeb check for completeness.
  if (!kIsWeb && Platform.isAndroid) {
    try {
      // Attempt to call a Wear OS specific method that *rethrows* PlatformException
      // if the method channel is not available (i.e., not Wear OS).
      // We use setAutoResumeEnabled(false) as a probe; the value doesn't matter here.
      await Wear.instance.setAutoResumeEnabled(false);

      // If the above call succeeded without throwing, it's Wear OS.
      isWearOS = true;
      debugPrint("Detected Wear OS device via successful platform channel call.");

      // Optional: Now that we know it's Wear OS, we *could* get the shape
      // if needed elsewhere, but getShape() might still return 'round'
      // on an error even on Wear OS. For just the boolean flag, the check
      // above is sufficient.
      // String shapeResult = await Wear.instance.getShape();
      // debugPrint("Wear OS shape: $shapeResult");

    } on PlatformException catch (e) {
      // This exception is expected on non-Wear OS Android devices.
      debugPrint(
          "PlatformException caught, indicating not a Wear OS device: $e");
      isWearOS = false;
    } catch (e) {
      // Catch any other unexpected errors during the detection process.
      debugPrint(
          "Unexpected error during Wear OS detection on Android: $e");
      isWearOS = false;
    }
  } else {
    // If not Android (or Web), it cannot be Wear OS.
    debugPrint("Not an Android platform, assuming not Wear OS.");
    isWearOS = false;
  }

  // Conditionally run the appropriate root widget
  runApp(
    isWearOS
        ? const WearOsPlaceholder() // Show placeholder for Wear OS
        : const MyApp(), // Run the standard app otherwise (from standard_app.dart)
  );
}

// A simple placeholder widget for Wear OS environments
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
