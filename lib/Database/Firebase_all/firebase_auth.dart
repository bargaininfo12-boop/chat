// v2.6.0 — Unified Auth, FCM, and Presence Manager
// 🔥 Multi-user safe | FCM auto-disable on logout | Optimized Firestore writes

import 'dart:async';
import 'package:bargain/Database/database_helper.dart';
import 'package:bargain/Services/user_service.dart';
import 'package:bargain/chat/services/userpresence.dart';
import 'package:bargain/chat/repository/message_repository.dart';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:bargain/chat/repository/message_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  // 🧩 Singleton
  FirebaseAuthService._internal();

  static final FirebaseAuthService instance = FirebaseAuthService._internal();

  factory FirebaseAuthService() => instance;

  // 🔗 Firebase references
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  StreamSubscription<String?>? _tokenRefreshSub;

  FirebaseAuth get auth => _auth;

  FirebaseFirestore get firestore => _firestore;

  GoogleSignIn get googleSignIn => _googleSignIn;

  // ============================================================
  // 💾 Save FCM token safely (avoids duplicates)
  // ============================================================
  Future<void> saveUserFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        debugPrint("⚠️ No FCM token found for ${user.uid}");
        return;
      }

      final tokenRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .doc(token);

      // 🔒 Avoid duplicate writes
      final exists = await tokenRef.get();
      if (exists.exists) {
        debugPrint("⚠️ Token already registered for ${user.uid}");
        return;
      }

      await tokenRef.set({
        'token': token,
        'platform': 'flutter',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(user.uid).set({
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint("✅ Token registered for ${user.uid}");
    } catch (e) {
      debugPrint("❌ Error saving FCM token: $e");
    }
  }

  // ============================================================
  // ♻️ Auto-refresh token listener
  // ============================================================
  void startTokenRefreshListener() {
    if (_tokenRefreshSub != null) return; // prevent duplicates

    _tokenRefreshSub =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          final user = _auth.currentUser;
          if (user == null) return;

          try {
            final tokenRef = _firestore
                .collection('users')
                .doc(user.uid)
                .collection('fcmTokens')
                .doc(newToken);

            await tokenRef.set({
              'token': newToken,
              'platform': 'flutter',
              'createdAt': FieldValue.serverTimestamp(),
              'lastActive': FieldValue.serverTimestamp(),
            });

            await _firestore.collection('users').doc(user.uid).set({
              'lastTokenUpdate': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            debugPrint("🔄 Token refreshed for ${user.uid}");
          } catch (e) {
            debugPrint("❌ Error updating refreshed token: $e");
          }
        });
  }

  // ============================================================
  // 🔐 Google Sign-In
  // ============================================================
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
      }

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null || googleAuth.accessToken == null) {
        return null;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final result = await _auth.signInWithCredential(credential);
      await saveUserFCMToken();
      startTokenRefreshListener();
      return result;
    } catch (e) {
      debugPrint("❌ Google Sign-in failed: $e");
      rethrow;
    }
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    final result = await _auth.signInWithCredential(credential);
    await saveUserFCMToken(); // Register FCM after login
    startTokenRefreshListener();
    debugPrint("✅ User signed in with custom credential: ${result.user?.uid}");
    return result;
  }


  // ============================================================
  // 🚪 Safe Logout (v2.6)
  // ============================================================
  Future<void> signOut({UserPresence? presence}) async {
    try {
      final user = _auth.currentUser;

      if (presence != null && user != null) {
        debugPrint("🔌 Disposing user presence...");
        await presence.dispose();
      }

      if (user != null) {
        final token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          try {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('fcmTokens')
                .doc(token)
                .delete();
            debugPrint("🧹 FCM token removed for ${user.uid}");
          } catch (e) {
            debugPrint("⚠️ Could not delete FCM token: $e");
          }
        }

        // Update Firestore presence
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'isOnline': false,
            'lastSeen': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint("📴 Firestore presence marked offline");
        } catch (e) {
          debugPrint("⚠️ Presence update failed: $e");
        }

        // Delete local FCM token
        try {
          await FirebaseMessaging.instance.deleteToken();
          debugPrint("🗑️ Local FCM token deleted");
        } catch (e) {
          debugPrint("⚠️ Could not delete local FCM token: $e");
        }
      }

      await _auth.signOut();
      await _googleSignIn.signOut();
      debugPrint("👋 User logged out cleanly");
    } catch (e, st) {
      debugPrint("❌ Logout error: $e");
      debugPrint(st.toString());
    }
  }

  // ============================================================
  // 🚪 UNIFIED COMPLETE LOGOUT
  // ============================================================
  // ============================================================
// 🚪 UNIFIED LOGOUT - Single source of truth (with full FCM cleanup)
// ============================================================
  Future<void> performCompleteLogout() async {
    try {
      final uid = _auth.currentUser?.uid;
      debugPrint('🚪 Starting complete logout for user: $uid');

      // 1️⃣ Stop chat listeners
      await MessageRepository.instance.dispose();

      // 2️⃣ Dispose presence
      if (uid != null) {
        await UserPresence(userId: uid).dispose();
      }

      // 3️⃣ Clear user + cache
      await UserService().clearUserData();
      await CustomCacheManager.clearAll();

      // 4️⃣ Remove FCM token
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && uid != null) {
        await _firestore.collection('users').doc(uid)
            .collection('fcmTokens').doc(token).delete();
      }
      await FirebaseMessaging.instance.deleteToken();

      // 5️⃣ Mark Firestore presence offline
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      // 6️⃣ Firebase + Google sign-out
      await _auth.signOut();
      await _googleSignIn.signOut();

      debugPrint('🎉 Complete logout finished successfully');
    } catch (e, st) {
      debugPrint('❌ performCompleteLogout error: $e');
      debugPrint(st.toString());
    }
  }

  // =============================================================
// 💣 Delete user completely (Firestore + Auth cleanup)
// =============================================================
  Future<void> deleteUser(User user) async {
    try {
      // Step 1️⃣ Delete all FCM tokens linked to this user
      final tokens = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('fcmTokens')
          .get();

      for (final doc in tokens.docs) {
        await doc.reference.delete();
      }

      // Step 2️⃣ Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Step 3️⃣ Delete FirebaseAuth user account
      await user.delete();

      debugPrint("🧨 User deleted successfully: ${user.uid}");
    } catch (e) {
      debugPrint("❌ Error deleting user: $e");
      rethrow;
    }
  }


  // ============================================================
  // 🧾 User Data Methods
  // ============================================================
  Future<void> updateUserInFirestore(User user, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final cached = await CustomCacheManager.loadJsonCache(
        'user_$uid',
        expiry: const Duration(hours: 24),
      );
      if (cached != null && cached.isNotEmpty) {
        return Map<String, dynamic>.from(cached.first);
      }

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = Map<String, dynamic>.from(doc.data()!);
      await CustomCacheManager.saveJsonCache('user_$uid', data);
      return data;
    } catch (e) {
      debugPrint("❌ getUserData error: $e");
      return null;
    }
  }

  // ============================================================
  // 🧠 Utility
  // ============================================================
  String? get currentUserId => _auth.currentUser?.uid;
}
