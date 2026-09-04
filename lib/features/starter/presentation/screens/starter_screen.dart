import 'package:flutter/material.dart';

/// The course starter screen, retained until Bahantabay implementation begins.
class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen> {
  int _taps = 0;

  void _handleTap() {
    setState(() {
      _taps++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Final Project'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rocket_launch,
                size: 72,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('It works', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'This is the starting point of your final project. '
                'Open lib/main.dart and start changing it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Taps: $_taps',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _handleTap,
                        icon: const Icon(Icons.touch_app),
                        label: const Text('Tap me'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Close the app and the count goes back to zero. '
                'Fixing that is what content/extending-your-app is about.',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
