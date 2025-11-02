import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:bargain/chat/services/userpresence.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';

class GlobalUserPresenceManager {
  GlobalUserPresenceManager._internal();
  static final GlobalUserPresenceManager _instance = GlobalUserPresenceManager._internal();
  static GlobalUserPresenceManager get instance => _instance;

  UserPresence? _userPresence;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  StreamSubscription<User?>? _authSubscription;

  Future<void> initialize() async {
    debugPrint("🚀 Initializing GlobalUserPresenceManager...");
    await _authSubscription?.cancel();
    _authSubscription = _authService.auth.authStateChanges().listen((user) async {
      if (user != null) {
        await _initializeUserPresence(user.uid);
      } else {
        await _disposeUserPresence();
      }
    });
  }

  Future<void> _initializeUserPresence(String userId) async {
    try {
      await _disposeUserPresence();
      _userPresence = UserPresence(userId: userId);
      await _userPresence!.initialize();
      debugPrint("✅ User presence initialized for: $userId");
    } catch (e) {
      debugPrint("❌ Error initializing presence: $e");
    }
  }

  Future<void> _disposeUserPresence() async {
    if (_userPresence != null) {
      try {
        await _userPresence!.dispose();
      } catch (e) {
        debugPrint("⚠️ Error disposing userPresence: $e");
      }
      _userPresence = null;
    }
  }

  Future<void> dispose() async {
    await _disposeUserPresence();
    await _authSubscription?.cancel();
    _authSubscription = null;
  }

  Future<void> updateActivity() async {
    if (_userPresence != null) {
      await _userPresence!.updateActivity();
    }
  }

  Map<String, dynamic> getStats() {
    final up = _userPresence;
    return {
      'has_user_presence_instance': up != null,
      'is_initialized': up?.isInitialized ?? false,
      'is_online': up?.isOnline ?? false,
    };
  }
}
