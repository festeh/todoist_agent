import 'package:flutter/material.dart';
import 'package:wear/wear.dart'; // Import wear package
import 'standard_app.dart'; // Import the standard app UI

void main() async {
  // Ensure Flutter bindings are initialized for async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();

  bool isWearOS = false;
  String? shapeResult; // Use nullable type

  try {
    // Attempt to get the shape from the Wear OS device.
    // getShape() might return 'round' on PlatformException.
    shapeResult = await Wear.instance.getShape();

    // Check if the result is explicitly 'round' or 'square'.
    // This check implicitly handles the case where getShape might return
    // 'round' due to an exception, as the exception would be caught below.
    // However, to be robust against potential future changes in the wear package
    // or unexpected return values, we explicitly check for the known shapes.
    if (shapeResult == 'round' || shapeResult == 'square') {
      // We successfully got a shape, assume it's Wear OS.
      // We rely on the fact that getShape() only returns these strings
      // on actual Wear OS devices or 'round' on exception.
      // The exception case is handled by the catch block.
      isWearOS = true;
      debugPrint("Detected Wear OS device: $shapeResult");
    } else {
      // Handle cases where getShape might return an empty string or unexpected value
      // other than 'round' or 'square'.
      debugPrint(
          "Device is likely not Wear OS (getShape returned '$shapeResult').");
    }
  } on PlatformException catch (e) {
    // If a PlatformException occurs (e.g., method not implemented on non-Wear OS),
    // the wear package's getShape() catches it and returns 'round'.
    // However, the original exception 'e' is NOT rethrown by the package.
    // Therefore, this catch block in main.dart might not be strictly necessary
    // if we only care about the return value of getShape().
    // But, keeping it helps log that an underlying platform issue occurred.
    debugPrint(
        "PlatformException while getting Wear shape, assuming not Wear OS: $e");
    // isWearOS remains false because the assignment inside the try block
    // depends on the shapeResult being 'round' or 'square', and if an exception
    // happened leading to the default 'round', we correctly interpret it here
    // as "not reliably Wear OS".
    // If getShape returned 'round' due to exception, shapeResult will be 'round',
    // but the logic inside the 'if' might have set isWearOS = true.
    // Let's explicitly set it to false here to be certain.
    isWearOS = false;
  } catch (e) {
    // Catch any other unexpected errors during the process.
    debugPrint("Unexpected error getting Wear shape, assuming not Wear OS: $e");
    isWearOS = false; // Ensure isWearOS is false on other errors too.
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
