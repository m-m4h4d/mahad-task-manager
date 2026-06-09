import 'package:flutter/material.dart';

class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 24),
              const SizedBox(width: 8),
              Text(
                'TaskPulse',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              TextButton(onPressed: () {}, child: const Text('About Us')),
              TextButton(onPressed: () {}, child: const Text('Privacy Policy')),
              TextButton(onPressed: () {}, child: const Text('Terms of Service')),
              TextButton(onPressed: () {}, child: const Text('Contact')),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} TaskPulse Inc. All rights reserved.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
