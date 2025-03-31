import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Screen'),
        // The AppBar automatically includes a back button when pushed via Navigator
      ),
      body: const Center(
        child: Text('You are on the second screen!'),
      ),
    );
  }
}
