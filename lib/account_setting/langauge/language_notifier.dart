import 'package:flutter/material.dart';

class LanguageNotifier extends ChangeNotifier {
  Locale _locale = const Locale('en'); // default English

  Locale get locale => _locale;

  void setLanguage(String code) {
    _locale = Locale(code);
    notifyListeners();
  }
}
