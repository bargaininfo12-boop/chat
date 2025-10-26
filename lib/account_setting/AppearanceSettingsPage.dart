// Version: 1.0.6
// Timestamp: May 04, 2025
// Updated: Removed ConditionalSearchBar from UI, updated import to remove main.dart reference

import 'package:bargain/main.dart'; // Only for ThemeNotifier
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance Settings'),
      ),
      body: Column(
        children: [
          RadioListTile<ThemeMode>(
            title: const Text('Light Theme'),
            value: ThemeMode.light,
            groupValue: themeNotifier.themeMode,
            onChanged: (mode) {
              if (mode != null) {
                themeNotifier.setThemeMode(mode);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Dark Theme'),
            value: ThemeMode.dark,
            groupValue: themeNotifier.themeMode,
            onChanged: (mode) {
              if (mode != null) {
                themeNotifier.setThemeMode(mode);
              }
            },
          ),
          RadioListTile<ThemeMode>(
            title: const Text('System Theme'),
            value: ThemeMode.system,
            groupValue: themeNotifier.themeMode,
            onChanged: (mode) {
              if (mode != null) {
                themeNotifier.setThemeMode(mode);
              }
            },
          ),
        ],
      ),
    );
  }
}
