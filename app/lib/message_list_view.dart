import 'package:flutter/material.dart';

class MessageListView extends StatelessWidget {
  final List<String> messages;

  const MessageListView({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    // Use Expanded to take available space if the parent allows it.
    // If used directly in a Column without Expanded, it might cause layout issues.
    // Consider how this widget will be used in the parent layout.
    // For direct use in AiFlow's Column, wrapping with Expanded there is appropriate.
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color:
                Theme.of(context)
                    .colorScheme
                    .surfaceVariant, // Use a subtle background color from the theme
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Text(
            messages[index],
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }
}
