// File: lib/account_setting/language_dialog.dart
// v1.0.4 — integrated with UserService + LanguageNotifier for runtime updates

import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/Services/user_service.dart';
import 'package:bargain/account_setting/langauge/language_notifier.dart';
import 'package:provider/provider.dart';

Future<void> showLanguageDialog(BuildContext context) async {
  final theme = Theme.of(context);

  final List<String> languages = [
    "English", "हिन्दी (Hindi)", "বাংলা (Bengali)", "ગુજરાતી (Gujarati)",
    "தமிழ் (Tamil)", "తెలుగు (Telugu)", "ಕನ್ನಡ (Kannada)", "മലയാളം (Malayalam)",
    "ਪੰਜਾਬੀ (Punjabi)", "اردو (Urdu)", "मराठी (Marathi)", "Odia (Oriya)",
    "Español (Spanish)", "Français (French)", "Deutsch (German)",
    "Português (Portuguese)", "Italiano (Italian)", "日本語 (Japanese)",
    "한국어 (Korean)", "Русский (Russian)", "Türkçe (Turkish)", "العربية (Arabic)",
    "ภาษาไทย (Thai)", "中文 (Chinese Simplified)", "繁體中文 (Chinese Traditional)",
  ];

  String searchQuery = "";
  String? selectedLang;

  await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final filteredLanguages = languages
              .where((lang) =>
              lang.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return AlertDialog(
            backgroundColor: AppTheme.surfaceColor(theme),
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.largeRadius,
            ),
            title: Text(
              "Choose Language",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(theme),
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 🔍 Search box
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search language...",
                      prefixIcon: Icon(Icons.search,
                          color: AppTheme.iconColor(theme)),
                      filled: true,
                      fillColor: AppTheme.inputFieldBackground(theme),
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.mediumRadius,
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => searchQuery = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // 📜 Language list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final lang = filteredLanguages[index];
                        return RadioListTile<String>(
                          title: Text(
                            lang,
                            style: TextStyle(
                              color: AppTheme.textPrimary(theme),
                            ),
                          ),
                          value: lang,
                          groupValue: selectedLang,
                          onChanged: (val) {
                            setState(() => selectedLang = val);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: selectedLang == null
                    ? null
                    : () async {
                  final userService =
                  Provider.of<UserService>(context, listen: false);
                  final langNotifier = Provider.of<LanguageNotifier>(
                      context,
                      listen: false);

                  // ✅ Save in Firestore + SQLite
                  final success =
                  await userService.saveLanguage(selectedLang!);

                  if (success) {
                    // ✅ Update app UI instantly
                    langNotifier.setLanguage(selectedLang!);
                  }

                  Navigator.pop(dialogContext, selectedLang);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(theme),
                  foregroundColor: AppTheme.textOnPrimary(theme),
                ),
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  ).then((value) async {
    if (value != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Language set to: $value"),
          backgroundColor: AppTheme.successColor(theme),
        ),
      );
    }
  });
}
