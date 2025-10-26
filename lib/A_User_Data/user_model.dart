// File: lib/A_User_Data/user_model.dart
// v3.1 — Adds soft-delete flags and 30-day deletion scheduling support

import 'package:bargain/chat/utils/timestamp_utils.dart';

class UserModel {
  final String uid;
  String? name;
  String? email;
  String? phoneNumber;
  String? photoURL;
  bool photoLocal;

  // Location fields
  String? address;
  String? city;
  String? state;
  String? pinCode;

  // Language field
  String? language;

  // Timestamp fields
  DateTime? createdAt;
  DateTime? lastUpdated;

  // 🔹 New deletion-related fields
  bool isDeleted;
  bool deletionPending;
  DateTime? deletionScheduledFor;

  UserModel({
    required this.uid,
    this.name,
    this.email,
    this.phoneNumber,
    this.photoURL,
    this.photoLocal = false,
    this.address,
    this.city,
    this.state,
    this.pinCode,
    this.language,
    this.createdAt,
    this.lastUpdated,
    this.isDeleted = false,
    this.deletionPending = false,
    this.deletionScheduledFor,
  });

  // ============================================================
  // 🧱 SQLite Mapping
  // ============================================================
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'photoLocal': photoLocal ? 1 : 0,
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'language': language,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated?.millisecondsSinceEpoch,
      'isDeleted': isDeleted ? 1 : 0,
      'deletionPending': deletionPending ? 1 : 0,
      'deletionScheduledFor': deletionScheduledFor?.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? externalUid}) {
    final uid = map['uid'] as String? ?? externalUid;
    if (uid == null) throw Exception("UserModel.fromMap: UID missing.");

    return UserModel(
      uid: uid,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      photoURL: map['photoURL'] as String?,
      photoLocal: (map['photoLocal'] ?? 0) == 1,
      address: map['address'] as String?,
      city: map['city'] as String?,
      state: map['state'] as String?,
      pinCode: map['pinCode'] as String?,
      language: map['language'] as String?,
      createdAt: map['createdAt'] != null ? TimestampUtils.toDateTime(map['createdAt']) : null,
      lastUpdated: map['lastUpdated'] != null ? TimestampUtils.toDateTime(map['lastUpdated']) : null,
      isDeleted: (map['isDeleted'] ?? 0) == 1,
      deletionPending: (map['deletionPending'] ?? 0) == 1,
      deletionScheduledFor: map['deletionScheduledFor'] != null
          ? DateTime.tryParse(map['deletionScheduledFor'])
          : null,
    );
  }

  // ============================================================
  // 🔄 Firestore / Cache JSON
  // ============================================================
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'photoLocal': photoLocal,
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'language': language,
      'createdAt': createdAt?.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'isDeleted': isDeleted,
      'deletionPending': deletionPending,
      'deletionScheduledFor': deletionScheduledFor?.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] ?? '',
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      photoURL: json['photoURL'],
      photoLocal: json['photoLocal'] == true,
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pinCode: json['pinCode'],
      language: json['language'],
      createdAt: TimestampUtils.toDateTime(json['createdAt']),
      lastUpdated: TimestampUtils.toDateTime(json['lastUpdated']),
      isDeleted: json['isDeleted'] == true,
      deletionPending: json['deletionPending'] == true,
      deletionScheduledFor: TimestampUtils.toDateTime(json['deletionScheduledFor']),
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'photoLocal': photoLocal,
      'address': address,
      'city': city,
      'state': state,
      'pinCode': pinCode,
      'language': language,
      'createdAt': createdAt != null
          ? TimestampUtils.toFirestoreTimestamp(createdAt!)
          : null,
      'lastUpdated': TimestampUtils.toFirestoreTimestamp(DateTime.now()),
      'isDeleted': isDeleted,
      'deletionPending': deletionPending,
      'deletionScheduledFor': deletionScheduledFor?.toIso8601String(),
    };
  }

  // ============================================================
  // ✏️ Copy with method
  // ============================================================
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? photoURL,
    bool? photoLocal,
    String? address,
    String? city,
    String? state,
    String? pinCode,
    String? language,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isDeleted,
    bool? deletionPending,
    DateTime? deletionScheduledFor,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      photoLocal: photoLocal ?? this.photoLocal,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pinCode: pinCode ?? this.pinCode,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
      deletionPending: deletionPending ?? this.deletionPending,
      deletionScheduledFor: deletionScheduledFor ?? this.deletionScheduledFor,
    );
  }

  // ============================================================
  // ✅ Validation helpers
  // ============================================================
  bool get hasBasicDetails =>
      name?.isNotEmpty == true &&
          email?.isNotEmpty == true &&
          phoneNumber?.isNotEmpty == true;

  bool get hasLocationDetails =>
      address?.isNotEmpty == true &&
          city?.isNotEmpty == true &&
          state?.isNotEmpty == true &&
          pinCode?.isNotEmpty == true;

  bool get isProfileComplete => hasBasicDetails && hasLocationDetails;

  double get profileCompletionPercentage {
    double total = 8.0;
    double completed = 0.0;

    if (name?.isNotEmpty == true) completed++;
    if (email?.isNotEmpty == true) completed++;
    if (phoneNumber?.isNotEmpty == true) completed++;
    if (address?.isNotEmpty == true) completed++;
    if (city?.isNotEmpty == true) completed++;
    if (state?.isNotEmpty == true) completed++;
    if (pinCode?.isNotEmpty == true) completed++;
    if (language?.isNotEmpty == true) completed++;

    return completed / total;
  }

  // ============================================================
  // 🧭 Display helpers
  // ============================================================
  String get displayName => name ?? email?.split('@').first ?? 'User';

  String get initials {
    if (name?.isNotEmpty == true) {
      List<String> parts = name!.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  String get fullAddress {
    final parts = [address, city, state, pinCode]
        .where((e) => e?.isNotEmpty == true)
        .cast<String>()
        .toList();
    return parts.join(', ');
  }

  String get shortAddress {
    final parts = [city, state]
        .where((e) => e?.isNotEmpty == true)
        .cast<String>()
        .toList();
    return parts.join(', ');
  }

  // ============================================================
  // 🔄 Validation functions
  // ============================================================
  bool isValidEmail() => email != null && RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(email!);

  bool isValidPhone() => phoneNumber != null && RegExp(r'^[6-9]\d{9}$').hasMatch(phoneNumber!);

  bool isValidPinCode() => pinCode != null && RegExp(r'^\d{6}$').hasMatch(pinCode!);

  // ============================================================
  // 🧩 Update methods
  // ============================================================
  void updateBasicDetails({
    required String name,
    required String email,
    required String phoneNumber,
  }) {
    this.name = name;
    this.email = email;
    this.phoneNumber = phoneNumber;
    this.lastUpdated = DateTime.now();
  }

  void updateLocationDetails({
    required String address,
    required String city,
    required String state,
    required String pinCode,
  }) {
    this.address = address;
    this.city = city;
    this.state = state;
    this.pinCode = pinCode;
    this.lastUpdated = DateTime.now();
  }

  void updateLanguage(String language) {
    this.language = language;
    this.lastUpdated = DateTime.now();
  }

  void updatePhoto({
    required String photoURL,
    bool isLocal = false,
  }) {
    this.photoURL = photoURL;
    this.photoLocal = isLocal;
    this.lastUpdated = DateTime.now();
  }

  // ============================================================
  // 🧠 Debug
  // ============================================================
  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, phone: $phoneNumber, '
        'deleted: $isDeleted, pending: $deletionPending, scheduled: $deletionScheduledFor)';
  }

  @override
  bool operator ==(Object other) => other is UserModel && other.uid == uid;
  @override
  int get hashCode => uid.hashCode;
}
