// v3.3.0 — Unified Session Manager
// ✅ Multi-user safe | ✅ FCM + Cache cleanup | ✅ Delete Account integrated

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/chat/Core%20Services/chat_service.dart';
import 'package:bargain/chat/services/userpresence.dart';
import 'package:bargain/chat/utils/network_manager.dart';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:bargain/login/login_page.dart';

class SessionManager {
  // =============================================================
  // 🚪 LOGOUT FLOW
  // =============================================================
  static Future<void> logout(BuildContext context) async {
    final navigator = Navigator.of(context);

    try {
      // 🌀 Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final firebase = FirebaseAuthService.instance;
      final uid = FirebaseAuth.instance.currentUser?.uid;

      // 1️⃣ Dispose user presence safely
      if (uid != null) {
        try {
          await UserPresence(userId: uid).dispose();
          debugPrint('✅ UserPresence disposed');
        } catch (e) {
          debugPrint('⚠️ Presence dispose warning: $e');
        }
      }

      // 2️⃣ Dispose chat and network services
      try {
        await ChatService.instance.dispose();
        debugPrint('✅ ChatService disposed');
      } catch (e) {
        debugPrint('⚠️ ChatService dispose warning: $e');
      }

      try {
        await NetworkManager.instance.dispose();
        debugPrint('✅ NetworkManager disposed');
      } catch (e) {
        debugPrint('⚠️ NetworkManager dispose warning: $e');
      }

      // 3️⃣ Clear FCM, local DB, caches, etc.
      try {
        await firebase.performCompleteLogout();
        debugPrint('✅ FirebaseAuthService cleanup done');
      } catch (e) {
        debugPrint('⚠️ performCompleteLogout warning: $e');
      }

      // 4️⃣ Clear local cache manager
      try {
        await CustomCacheManager.clearAll();
        debugPrint('✅ CustomCacheManager cleared');
      } catch (e) {
        debugPrint('⚠️ CustomCacheManager warning: $e');
      }

      // 5️⃣ Navigate to login screen safely
      if (!context.mounted) return;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );

      debugPrint('🎉 Complete logout finished successfully');
    } catch (e, st) {
      debugPrint('❌ Logout error: $e');
      debugPrint(st.toString());
    } finally {
      // Always close the loading dialog
      if (navigator.canPop()) navigator.pop();
    }
  }

  // =============================================================
  // 🧨 DELETE ACCOUNT FLOW
  // =============================================================
  static Future<void> deleteAccount(BuildContext context) async {
    final navigator = Navigator.of(context);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 🌀 Show blocking loader
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final firebase = FirebaseAuthService.instance;

      // Step 1️⃣ Dispose user presence
      try {
        await UserPresence(userId: user.uid).dispose();
        debugPrint('✅ UserPresence disposed before deletion');
      } catch (e) {
        debugPrint('⚠️ Presence dispose warning before delete: $e');
      }

      // Step 2️⃣ Delete from FirebaseAuth & Firestore
      await firebase.deleteUser(user);
      debugPrint('🗑️ Account deleted from Firebase');

      // Step 3️⃣ Clear all local data
      try {
        await CustomCacheManager.clearAll();
        debugPrint('✅ CustomCacheManager cleared after delete');
      } catch (e) {
        debugPrint('⚠️ Cache clear warning after delete: $e');
      }

      // Step 4️⃣ Navigate to login
      if (!context.mounted) return;

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );

      debugPrint('🎉 Account deletion complete');
    } catch (e) {
      debugPrint('❌ Delete account error: $e');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    } finally {
      if (navigator.canPop()) navigator.pop();
    }
  }

  // =============================================================
  // 🧠 EXTRA: FORCE REFRESH (useful for user switch)
  // =============================================================
  static Future<void> forceFullRefresh(BuildContext context) async {
    try {
      await ChatService.instance.dispose();
      await NetworkManager.instance.dispose();
      await CustomCacheManager.clearAll();
      debugPrint('🔄 Force full refresh complete.');
    } catch (e) {
      debugPrint('⚠️ Force refresh error: $e');
    }
  }
}
