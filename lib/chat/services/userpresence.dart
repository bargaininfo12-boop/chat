// v3.0.0 — Safe Logout + Throttled Presence + Firestore mirror fix
// Works perfectly with FirebaseAuthService v2.4.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

/// Handles realtime user presence (online/offline/activity) for Firestore + RTDB.
/// Designed to safely stop presence writes on logout without permission errors.
class UserPresence with WidgetsBindingObserver {
  final String userId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _userStatusRef;

  bool _isInitialized = false;
  bool _isOnline = false;
  bool _isDisposed = false;

  Timer? _heartbeatTimer;
  StreamSubscription? _connectionSubscription;

  // --- Throttling controls
  DateTime _lastPresenceWrite = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastActivityWrite = DateTime.fromMillisecondsSinceEpoch(0);

  static const _presenceMinGap = Duration(seconds: 10); // limit presence writes
  static const _activityMinGap = Duration(seconds: 20); // limit activity writes

  UserPresence({required this.userId})
      : _userStatusRef = FirebaseDatabase.instance.ref('status/$userId');

  // ------------------------------------------------------------
  // 🔧 Initialize and attach listeners
  // ------------------------------------------------------------
  Future<void> initialize() async {
    if (_isInitialized || _isDisposed) return;

    try {
      WidgetsBinding.instance.addObserver(this);
      _setupConnectionMonitoring();
      _setupHeartbeat();

      _isInitialized = true;
      await setOnline();

      debugPrint("✅ UserPresence initialized for $userId");
    } catch (e) {
      debugPrint("❌ UserPresence initialization error for $userId: $e");
    }
  }

  // ------------------------------------------------------------
  // 🌐 Firebase Realtime DB connection listener
  // ------------------------------------------------------------
  void _setupConnectionMonitoring() {
    _connectionSubscription =
        FirebaseDatabase.instance.ref('.info/connected').onValue.listen(
              (event) async {
            final connected = event.snapshot.value as bool? ?? false;
            if (!_isInitialized || _isDisposed) return;
            if (connected && _isOnline) {
              await _writePresence(true); // ensure sync after reconnect
            }
          },
        );
  }

  // ------------------------------------------------------------
  // ⏰ Heartbeat timer to refresh presence
  // ------------------------------------------------------------
  void _setupHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      if (_isInitialized && !_isDisposed && _isOnline) {
        await _writePresence(true);
      }
    });
  }

  // ------------------------------------------------------------
  // 💾 Core presence writer (with throttling)
  // ------------------------------------------------------------
  Future<void> _writePresence(bool desiredOnline) async {
    if (_isDisposed) return;

    final now = DateTime.now();
    final sinceLastWrite = now.difference(_lastPresenceWrite);

    if (_isOnline == desiredOnline && sinceLastWrite < _presenceMinGap) {
      return; // skip redundant writes
    }

    _isOnline = desiredOnline;
    _lastPresenceWrite = now;

    try {
      if (desiredOnline) {
        // setup disconnect handler before setting online
        await _userStatusRef.onDisconnect().update({
          'isOnline': false,
          'disconnectedAt': ServerValue.timestamp,
        });

        await _userStatusRef.update({
          'isOnline': true,
          'lastSeen': ServerValue.timestamp,
        });
      } else {
        await _userStatusRef.update({
          'isOnline': false,
          'disconnectedAt': ServerValue.timestamp,
        });
        await _userStatusRef.onDisconnect().cancel();
      }

      // Firestore mirror — safe merge
      await _firestore.collection('users').doc(userId).set({
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));


      debugPrint("✅ Presence updated (online=$desiredOnline)");
    } catch (e) {
      debugPrint("❌ Presence write error: $e");
    }
  }

  // ------------------------------------------------------------
  // 🔁 Public APIs
  // ------------------------------------------------------------
  Future<void> setOnline() async => _writePresence(true);

  Future<void> setOffline() async => _writePresence(false);

  Future<void> updateActivity() async {
    if (!_isInitialized || _isDisposed || !_isOnline) return;
    final now = DateTime.now();
    if (now.difference(_lastActivityWrite) < _activityMinGap) return;

    _lastActivityWrite = now;
    try {
      await _firestore.collection('users').doc(userId).set({
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("✅ Activity recorded");
    } catch (e) {
      debugPrint("❌ Activity write error: $e");
    }
  }

  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  // ------------------------------------------------------------
  // 📊 Optional diagnostics
  // ------------------------------------------------------------
  Map<String, dynamic> getPresenceStats() => {
    'user_id': userId,
    'is_initialized': _isInitialized,
    'is_online': _isOnline,
    'last_presence_write': _lastPresenceWrite.toIso8601String(),
    'last_activity_write': _lastActivityWrite.toIso8601String(),
  };

  // ------------------------------------------------------------
  // 💤 App Lifecycle Handling
  // ------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isInitialized || _isDisposed) return;
    switch (state) {
      case AppLifecycleState.resumed:
        setOnline();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        setOffline();
        break;
      case AppLifecycleState.inactive:
      // skip: user is temporarily inactive (e.g., switch apps)
        break;
    }
  }

  // ------------------------------------------------------------
  // 🧹 Safe Disposal — called during logout
  // ------------------------------------------------------------
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    try {
      if (_isInitialized) {
        await _writePresence(false);
      }
    } catch (e) {
      debugPrint("⚠️ Presence cleanup error: $e");
    }

    _heartbeatTimer?.cancel();
    await _connectionSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    _isInitialized = false;
    _isOnline = false;

    debugPrint("✅ UserPresence disposed for $userId");
  }
}
