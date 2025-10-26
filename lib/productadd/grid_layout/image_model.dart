import 'package:cloud_firestore/cloud_firestore.dart';

class ImageModel {
  // Identity
  final String id;
  final DocumentReference? docRef; // nullable for cached items

  // Media
  final List<String> imageUrls;
  final List<String> videoUrls;

  // Category / owner
  final String category;
  final String subcategory;
  final String userId;
  final String productId;

  // Location pieces
  final String? city;
  final String? state;

  // Price / time
  final String? price;
  final DateTime? time;

  // Likes & status (mutable-ish)
  int likeCount;
  List<String> likedBy;
  bool isActive;
  bool isSoldOut;
  bool isDeleted;

  // Dynamic details & description (top-level)
  final Map<String, dynamic>? productDetails;
  final String description;

  ImageModel({
    required this.id,
    this.docRef,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.category = '',
    this.subcategory = '',
    this.userId = '',
    this.productId = '',
    this.city,
    this.state,
    this.price,
    this.time,
    this.likeCount = 0,
    List<String>? likedBy,
    this.isActive = true,
    this.isSoldOut = false,
    this.isDeleted = false,
    this.productDetails,
    this.description = '',
  }) : likedBy = likedBy ?? [];

  // Convenience: formatted location
  String get location {
    final parts = <String>[];
    if (city != null && city!.trim().isNotEmpty) parts.add(city!.trim());
    if (state != null && state!.trim().isNotEmpty) parts.add(state!.trim());
    return parts.join(', ');
  }

  /// ---------------- Firestore -> Model ----------------
  factory ImageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final media = (data['media'] as Map<String, dynamic>?) ?? {};
    final mainCat = (data['MainCategory'] as Map<String, dynamic>?) ?? {};
    final product = (data['Product'] as Map<String, dynamic>?) ?? {};
    final priceMap = (data['Price'] as Map<String, dynamic>?) ?? {};
    final location = (data['Location'] as Map<String, dynamic>?) ?? {};
    final detailsWrapper = (data['Details'] as Map<String, dynamic>?) ?? {};

    // image / video lists
    final imageList = (media['imageUris'] as List<dynamic>?)
        ?.map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList() ??
        <String>[];

    final videoList = (media['videoUris'] as List<dynamic>?)
        ?.map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList() ??
        <String>[];

    // timestamp handling
    DateTime? parsedTime;
    final ts = media['timestamp'];
    if (ts is Timestamp) parsedTime = ts.toDate();
    else if (ts is int) parsedTime = DateTime.fromMillisecondsSinceEpoch(ts);

    // likes parsing (safe)
    int likesValue = 0;
    final dynamic likesRaw = product['likes'];
    if (likesRaw is int) likesValue = likesRaw;
    else if (likesRaw is num) likesValue = likesRaw.toInt();
    else if (likesRaw is String) likesValue = int.tryParse(likesRaw) ?? 0;

    // likedBy list
    final likedByList = (product['likedBy'] as List<dynamic>?)
        ?.map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList() ??
        <String>[];

    // Description (top-level)
    final description = (data['Description'] ?? '').toString();

    return ImageModel(
      id: doc.id,
      docRef: doc.reference,
      imageUrls: imageList,
      videoUrls: videoList,
      category: (mainCat['category'] ?? '').toString(),
      subcategory: (mainCat['subcategory'] ?? '').toString(),
      userId: (product['uid'] ?? '').toString(),
      productId: (product['productId'] ?? doc.id).toString(),
      city: (location['city'] ?? '').toString(),
      state: (location['state'] ?? '').toString(),
      price: (priceMap['priceData'] ?? '').toString(),
      time: parsedTime,
      likeCount: likesValue,
      likedBy: likedByList,
      isActive: product['isActive'] == true,
      isSoldOut: product['isSoldOut'] == true,
      isDeleted: product['isDeleted'] == true,
      productDetails:
      (detailsWrapper['ProductDetails'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      description: description,
    );
  }

  /// ---------------- Cache JSON -> Model ----------------
  /// This is used by DataService when loading from SharedPreferences cache.
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as Map<String, dynamic>?) ?? {};
    final mainCat = (json['MainCategory'] as Map<String, dynamic>?) ?? {};
    final product = (json['Product'] as Map<String, dynamic>?) ?? {};
    final priceMap = (json['Price'] as Map<String, dynamic>?) ?? {};
    final location = (json['Location'] as Map<String, dynamic>?) ?? {};
    final detailsWrapper = (json['Details'] as Map<String, dynamic>?) ?? {};

    // image/video lists (may be List<dynamic> or missing)
    final imageList = (media['imageUris'] as List<dynamic>?)
        ?.map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList() ??
        <String>[];

    final videoList = (media['videoUris'] as List<dynamic>?)
        ?.map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList() ??
        <String>[];

    // timestamp (stored as millisecondsSinceEpoch in cache)
    DateTime? parsedTime;
    final ts = media['timestamp'];
    if (ts is int) parsedTime = DateTime.fromMillisecondsSinceEpoch(ts);
    else if (ts is String) {
      final p = int.tryParse(ts);
      if (p != null) parsedTime = DateTime.fromMillisecondsSinceEpoch(p);
    }

    // likes
    int likesValue = 0;
    final dynamic likesRaw = product['likes'];
    if (likesRaw is int) likesValue = likesRaw;
    else if (likesRaw is num) likesValue = likesRaw.toInt();
    else if (likesRaw is String) likesValue = int.tryParse(likesRaw) ?? 0;

    final likedByList = (product['likedBy'] as List<dynamic>?)
        ?.map((e) => e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList() ??
        <String>[];

    // docRef from path (if present)
    DocumentReference? docRef;
    if (json['docPath'] != null && (json['docPath'] as String).isNotEmpty) {
      try {
        docRef = FirebaseFirestore.instance.doc(json['docPath'].toString());
      } catch (_) {
        docRef = null;
      }
    }

    final description = (json['Description'] ?? '').toString();

    return ImageModel(
      id: json['id']?.toString() ?? '',
      docRef: docRef,
      imageUrls: imageList,
      videoUrls: videoList,
      category: (mainCat['category'] ?? '').toString(),
      subcategory: (mainCat['subcategory'] ?? '').toString(),
      userId: (product['uid'] ?? '').toString(),
      productId: (product['productId'] ?? '').toString(),
      city: (location['city'] ?? '').toString(),
      state: (location['state'] ?? '').toString(),
      price: (priceMap['priceData'] ?? '').toString(),
      time: parsedTime,
      likeCount: likesValue,
      likedBy: likedByList,
      isActive: product['isActive'] == true,
      isSoldOut: product['isSoldOut'] == true,
      isDeleted: product['isDeleted'] == true,
      productDetails:
      (detailsWrapper['ProductDetails'] as Map<String, dynamic>?) ??
          <String, dynamic>{},
      description: description,
    );
  }

  /// ---------------- Model -> Cache JSON ----------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'docPath': docRef?.path,
      'media': {
        'imageUris': imageUrls,
        'videoUris': videoUrls,
        'timestamp': time?.millisecondsSinceEpoch,
      },
      'MainCategory': {
        'category': category,
        'subcategory': subcategory,
      },
      'Product': {
        'uid': userId,
        'productId': productId,
        'likes': likeCount,
        'likedBy': likedBy,
        'isActive': isActive,
        'isSoldOut': isSoldOut,
        'isDeleted': isDeleted,
      },
      'Price': {'priceData': price},
      'Location': {'city': city, 'state': state},
      'Description': description,
      if (productDetails != null) 'Details': {'ProductDetails': productDetails},
    };
  }

  /// ---------------- copyWith ----------------
  ImageModel copyWith({
    String? id,
    DocumentReference? docRef,
    List<String>? imageUrls,
    List<String>? videoUrls,
    String? category,
    String? subcategory,
    String? userId,
    String? productId,
    String? city,
    String? state,
    String? price,
    DateTime? time,
    int? likeCount,
    List<String>? likedBy,
    bool? isActive,
    bool? isSoldOut,
    bool? isDeleted,
    Map<String, dynamic>? productDetails,
    String? description,
  }) {
    return ImageModel(
      id: id ?? this.id,
      docRef: docRef ?? this.docRef,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      city: city ?? this.city,
      state: state ?? this.state,
      price: price ?? this.price,
      time: time ?? this.time,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? List<String>.from(this.likedBy),
      isActive: isActive ?? this.isActive,
      isSoldOut: isSoldOut ?? this.isSoldOut,
      isDeleted: isDeleted ?? this.isDeleted,
      productDetails: productDetails ?? this.productDetails,
      description: description ?? this.description,
    );
  }

  @override
  String toString() {
    return 'ImageModel(id: $id, productId: $productId, likes: $likeCount, active: $isActive, soldOut: $isSoldOut, deleted: $isDeleted, images: ${imageUrls.length})';
  }
}
