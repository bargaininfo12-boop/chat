import 'package:flutter/foundation.dart';

/// Simple app-level auth state holder
class AppAuthProvider with ChangeNotifier {
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  void setUserId(String? userId) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      notifyListeners();
    }
  }
}
