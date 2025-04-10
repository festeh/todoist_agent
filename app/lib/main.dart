import 'package:flutter/material.dart';
import 'package:wear/wear.dart'; // Import wear package
import 'standard_app.dart'; // Import the standard app UI

void main() async {
  // Ensure Flutter bindings are initialized for async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();

  bool isWearOS = false;
  try {
    // Attempt to detect the shape of the Wear OS device
    final shape = await WearShape.detect();
    // If shape is non-null, it's likely a Wear OS device
    if (shape != null) {
      isWearOS = true;
      debugPrint(
          "Detected Wear OS device: ${shape == WearShape.round ? 'Round' : 'Square'}");
    } else {
      debugPrint("Device is not Wear OS (shape detection returned null).");
    }
  } catch (e) {
    // Catch potential errors during detection (e.g., platform issues)
    debugPrint("Could not detect WearShape, assuming not Wear OS: $e");
    // Depending on the app's requirements, you might want to default isWearOS
    // to false or handle the error differently.
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
