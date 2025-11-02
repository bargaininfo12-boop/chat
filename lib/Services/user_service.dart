import 'package:bargain/A_User_Data/user_model.dart';
import 'package:bargain/Database/database_helper.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum UserProfileStatus {
  incomplete,
  locationNeeded,
  complete,
}

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // ============================================================
  // 🔄 Initialize user after login (Firestore → SQLite → Cache)
  // ============================================================
  Future<UserProfileStatus> initializeUser(User firebaseUser) async {
    try {
      debugPrint('🔄 Initializing user: ${firebaseUser.uid}');

      // 1️⃣ Firestore first
      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      final userDoc = await docRef.get();

      if (!userDoc.exists || userDoc.data() == null) {
        debugPrint('❌ No Firestore document — creating new one');
        final newUser = UserModel(
          uid: firebaseUser.uid,
          name: firebaseUser.displayName,
          email: firebaseUser.email,
          phoneNumber: firebaseUser.phoneNumber?.replaceAll('+91', ''),
          photoURL: firebaseUser.photoURL,
          createdAt: DateTime.now().toUtc(),
          lastUpdated: DateTime.now().toUtc(),
          language: 'English',
          isDeleted: false,
          deletionPending: false,
        );
        await docRef.set(newUser.toFirestoreMap());
        await _databaseHelper.insertUser(newUser);
        await CustomCacheManager.saveJsonCache('user_${firebaseUser.uid}', newUser.toJson());
        _currentUser = newUser;
        return UserProfileStatus.incomplete;
      }

      final data = userDoc.data() as Map<String, dynamic>;

      // 2️⃣ Handle soft deletion
      if (data['deletionPending'] == true && data['deletionScheduledFor'] != null) {
        final scheduled = DateTime.tryParse(data['deletionScheduledFor']);
        if (scheduled != null && DateTime.now().isBefore(scheduled)) {
          debugPrint('♻️ Re-login before deletion → cancelling scheduled deletion');
          await docRef.update({
            'isDeleted': false,
            'deletionPending': false,
            'deletionScheduledFor': FieldValue.delete(),
            'deletedAt': FieldValue.delete(),
            'status': 'active',
          });
        } else if (scheduled != null && DateTime.now().isAfter(scheduled)) {
          debugPrint('🚫 Account past deletion deadline');
          throw Exception("Account permanently deleted");
        }
      }

      // 3️⃣ Sync Firestore → SQLite + Cache
      final firestoreUser = UserModel.fromJson({...data, 'uid': firebaseUser.uid});
      _currentUser = firestoreUser;

      await _databaseHelper.insertUser(firestoreUser);
      await CustomCacheManager.saveJsonCache('user_${firebaseUser.uid}', firestoreUser.toJson());

      debugPrint('✅ Profile loaded: ${_currentUser?.name}');
      return _getProfileStatus(firestoreUser);
    } catch (e) {
      debugPrint('❌ initializeUser error: $e');
      return UserProfileStatus.incomplete;
    }
  }

  // ============================================================
  // 🔍 Fetch any user by UID (cache → SQLite → Firestore)
  // ============================================================
  Future<UserModel?> getUserById(String uid) async {
    try {
      // 1️⃣ Try cache
      final cached = await CustomCacheManager.loadJsonCache('user_$uid');
      if (cached != null && cached.isNotEmpty) {
        return UserModel.fromJson(cached.first);
      }

      // 2️⃣ Try SQLite
      final local = await _databaseHelper.getUser(uid);
      if (local != null) return local;

      // 3️⃣ Firestore
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return null;

      final data = doc.data()!;
      final user = UserModel.fromJson({...data, 'uid': uid});

      await _databaseHelper.insertUser(user);
      await CustomCacheManager.saveJsonCache('user_$uid', user.toJson());

      return user;
    } catch (e) {
      debugPrint('❌ getUserById error: $e');
      return null;
    }
  }

  // ============================================================
  // ✏️ Update user profile
  // ============================================================
  Future<bool> updateUserProfile({
    String? name,
    String? email,
    String? phoneNumber,
    String? address,
    String? city,
    String? state,
    String? pinCode,
    String? language,
    String? photoURL,
  }) async {
    if (_currentUser == null) return false;
    try {
      final updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
        if (name != null) 'name': name.trim(),
        if (email != null) 'email': email.trim(),
        if (phoneNumber != null) 'phoneNumber': phoneNumber.trim(),
        if (address != null) 'address': address.trim(),
        if (city != null) 'city': city.trim(),
        if (state != null) 'state': state.trim(),
        if (pinCode != null) 'pinCode': pinCode.trim(),
        if (language != null) 'language': language.trim(),
        if (photoURL != null) 'photoURL': photoURL,
      };

      await _firestore.collection('users').doc(_currentUser!.uid).update(updateData);

      _currentUser = _currentUser!.copyWith(
        name: name,
        email: email,
        phoneNumber: phoneNumber,
        address: address,
        city: city,
        state: state,
        pinCode: pinCode,
        language: language,
        photoURL: photoURL,
        lastUpdated: DateTime.now(),
      );

      await _databaseHelper.updateUser(_currentUser!);
      await CustomCacheManager.saveJsonCache('user_${_currentUser!.uid}', _currentUser!.toJson());
      debugPrint('✅ Profile updated');
      return true;
    } catch (e) {
      debugPrint('❌ updateUserProfile: $e');
      return false;
    }
  }

  // ============================================================
  // 🗓️ Schedule soft deletion
  // ============================================================
  Future<void> scheduleUserDeletion() async {
    if (_currentUser == null) return;
    try {
      final scheduled = DateTime.now().toUtc().add(const Duration(days: 30));
      final uid = _currentUser!.uid;

      await _firestore.collection('users').doc(uid).update({
        'isDeleted': false,
        'deletionPending': true,
        'deletionScheduledFor': scheduled.toIso8601String(),
        'status': 'pending_delete',
      });

      _currentUser = _currentUser!.copyWith(
        isDeleted: false,
        deletionPending: true,
        deletionScheduledFor: scheduled,
      );

      await _databaseHelper.updateUser(_currentUser!);
      await CustomCacheManager.saveJsonCache('user_$uid', _currentUser!.toJson());

      debugPrint('🕒 Account scheduled for deletion on: $scheduled');
    } catch (e) {
      debugPrint('❌ scheduleUserDeletion: $e');
    }
  }




  // ============================================================
  // 🌍 Save language
  // ============================================================
  Future<bool> saveLanguage(String language) async {
    if (_currentUser == null) return false;
    try {
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'language': language,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _currentUser = _currentUser!.copyWith(language: language);
      await _databaseHelper.updateUser(_currentUser!);
      await CustomCacheManager.saveJsonCache('user_${_currentUser!.uid}', _currentUser!.toJson());
      return true;
    } catch (e) {
      debugPrint('❌ saveLanguage: $e');
      return false;
    }
  }

  // ============================================================
  // 📍 Location data
  // ============================================================
  Future<bool> saveLocationData({
    required String address,
    required String city,
    required String state,
    required String pinCode,
  }) async =>
      updateUserProfile(
        address: address,
        city: city,
        state: state,
        pinCode: pinCode,
      );

  // ============================================================
  // 🧩 Profile status helpers
  // ============================================================
  UserProfileStatus _getProfileStatus(UserModel user) {
    if (!_isValid(user.name) || !_isValid(user.email) || !_isValid(user.phoneNumber)) {
      return UserProfileStatus.incomplete;
    }
    if (!_isValid(user.address) ||
        !_isValid(user.city) ||
        !_isValid(user.state) ||
        !_isValid(user.pinCode)) {
      return UserProfileStatus.locationNeeded;
    }
    return UserProfileStatus.complete;
  }

  bool _isValid(String? v) => v != null && v.trim().isNotEmpty;

  // ============================================================
  // 🔄 Refresh data
  // ============================================================
  Future<bool> refreshUserData() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      final refreshed = UserModel.fromJson({...data, 'uid': user.uid});
      _currentUser = refreshed;
      await _databaseHelper.insertUser(refreshed);
      await CustomCacheManager.saveJsonCache('user_${user.uid}', refreshed.toJson());
      debugPrint('🔁 User refreshed');
      return true;
    } catch (e) {
      debugPrint('❌ refreshUserData: $e');
      return false;
    }
  }

  // ============================================================
  // 🚪 Logout / Clear
  // ============================================================
  Future<void> logout() async {
    _currentUser = null;
    debugPrint('👋 UserService memory cleared.');
  }

  Future<void> clearUserData() async {
    try {
      final uid = _authService.currentUserId;
      if (uid != null) {
        await _databaseHelper.deleteUser(uid);
        await CustomCacheManager.clearJsonCache('user_$uid');
      }
      await CustomCacheManager.clearAll();
      _currentUser = null;
      debugPrint('🗑️ All local user data cleared.');
    } catch (e) {
      debugPrint('❌ clearUserData: $e');
    }
  }

  // ============================================================
  // 📊 Getters
  // ============================================================
  bool get isLoggedIn =>
      _auth.currentUser != null && _currentUser != null;

  bool get isProfileComplete =>
      _getProfileStatus(_currentUser ?? UserModel(uid: '')) ==
          UserProfileStatus.complete;

  double get profileCompletionPercentage =>
      _currentUser?.profileCompletionPercentage ?? 0.0;
}
