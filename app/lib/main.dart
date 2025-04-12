import 'package:flutter/material.dart';
import 'package:wear/wear.dart'; // Import wear package
import 'standard_app.dart'; // Import the standard app UI

void main() async {
  // Ensure Flutter bindings are initialized for async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();

  bool isWearOS = false;
  try {
    // Attempt to get the shape from the Wear OS device
    // Wear.instance.getShape() returns a Future<String> ('round' or 'square')
    // An empty string or error likely means it's not Wear OS.
    final shapeResult = await Wear.instance.getShape();

    // Check if the result indicates a known Wear OS shape
    if (shapeResult == 'round' || shapeResult == 'square') {
      isWearOS = true;
      debugPrint("Detected Wear OS device: $shapeResult");
    } else {
      // Handle cases where getShape might return an empty string or unexpected value
      debugPrint(
          "Device is likely not Wear OS (getShape returned '$shapeResult').");
    }
  } catch (e) {
    // Catch potential errors during the platform channel call
    debugPrint("Could not get Wear shape, assuming not Wear OS: $e");
    // Default isWearOS remains false
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
