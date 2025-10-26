import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ✅ DataHolder — Global static holder for product creation flow
/// Handles temporary storage of product data before upload to Firestore.
class DataHolder {
  static String? uid;
  static String? productId;

  // Media
  static List<String> imageUrls = [];
  static List<String> videoUrls = [];

  // Category
  static String category = "";
  static String subcategory = "";

  // Product Details
  static String subcategoryData = "";
  static bool isActive = true;
  static bool isSoldOut = false;
  static bool isDeleted = false;
  static Map<String, dynamic> details = {}; // Flexible key/value data
  static String? description; // ✅ NEW FIELD for top-level Description

  // Price
  static String? priceData;
  static String? rent;
  static String? securityDeposit;

  // Location
  static String? locationData;
  static double? locationLat;
  static double? locationLong;
  static String? streetAddress;
  static String? area;
  static String? city;
  static String? state;
  static String? pincode;

  /// ✅ Start a new product (generate productId + set uid)
  static Future<void> startNewProduct() async {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) throw Exception("⚠️ User not logged in");

    final newProductId = firestore.collection("products").doc().id;
    setUid(user.uid);
    setProductId(newProductId);

    print("🆕 New product started with ID: $newProductId");
  }

  /// ✅ Clear all stored product data
  static Future<void> clearAllData() async {
    uid = null;
    productId = null;

    imageUrls = [];
    videoUrls = [];

    category = "";
    subcategory = "";

    subcategoryData = "";
    isActive = true;
    isSoldOut = false;
    isDeleted = false;
    details = {};
    description = null;

    priceData = null;
    rent = null;
    securityDeposit = null;

    locationData = null;
    locationLat = null;
    locationLong = null;
    streetAddress = null;
    area = null;
    city = null;
    state = null;
    pincode = null;

    print("🧹 DataHolder cleared, ready for new product");
  }

  /// ✅ Setters
  static void setProductId(String newProductId) => productId = newProductId;
  static void setUid(String newUid) => uid = newUid;

  /// ✅ Convert to Firestore Map
  static Map<String, dynamic> toMap() {
    return {
      "Product": {
        "isActive": isActive,
        "isSoldOut": isSoldOut,
        "isDeleted": isDeleted,
        "uid": uid,
        "productId": productId,
        "likes": 0,
      },
      "media": {
        "imageUris": imageUrls,
        "videoUris": videoUrls,
        "timestamp": Timestamp.now(),
        "uid": uid,
        "productId": productId,
      },
      "MainCategory": {
        "category": category,
        "subcategory": subcategory,
        "uid": uid,
        "productId": productId,
      },
      "Price": {
        "priceData": priceData,
        "rent": rent,
        "securityDeposit": securityDeposit,
        "uid": uid,
        "productId": productId,
      },
      "Location": {
        "locationData": locationData,
        "locationLat": locationLat,
        "locationLong": locationLong,
        "streetAddress": streetAddress ?? area,
        "city": city,
        "state": state,
        "pincode": pincode,
        "uid": uid,
        "productId": productId,
      },
      if (details.isNotEmpty)
        "Details": {
          "ProductDetails": details,
          "subcategoryData": subcategoryData,
          "uid": uid,
          "productId": productId,
        },
      if (description != null && description!.isNotEmpty)
        "Description": description, // ✅ Separate Firestore field
    };
  }
}
