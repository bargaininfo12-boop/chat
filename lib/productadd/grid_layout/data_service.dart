// ✅ FINAL DataService.dart (fixed for SearchPage real-time + instant cache emit)
// Handles Firestore streaming, cache, pagination, likes, filtering, etc.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // ✅ Add this
import 'package:bargain/productadd/grid_layout/image_model.dart';

class DataService {
  static const int _limit = 20;
  static const String _cacheKey = 'cached_products';
  static const String _cacheVersionKey = 'cache_version';
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const Duration _debounceDelay = Duration(milliseconds: 500);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  QueryDocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isFetching = false;
  bool _isInitialized = false;

  final List<ImageModel> _images = [];
  List<ImageModel> get images => List.unmodifiable(_images);

  StreamSubscription? _streamSubscription;
  Timer? _debounceTimer;
  final _imagesStreamController = StreamController<List<ImageModel>>.broadcast();

  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._internal();

  DataService._internal() {
    _initialize();
  }
  factory DataService() => instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ---------------- Initialization / stream ----------------
  Future<void> _initialize() async {
    if (_isInitialized) return;
    try {
      _isInitialized = true;

      await _loadCachedImages();
      if (_images.isNotEmpty) _emitImages();

      final snapshot = await _buildBaseQuery().limit(_limit).get();
      if (snapshot.docs.isNotEmpty) {
        _updateImagesFromSnapshot(snapshot);
        await _saveImagesToCache();
        _emitImages();
      }

      _startFirestoreStream();
    } catch (e) {
      _imagesStreamController.addError('Initialization failed: $e');
    }
  }

  Stream<List<ImageModel>> getImages() async* {
    const cacheKey = 'products_all';

    try {
      // 1️⃣ Load cached images first (instant display)
      final cached = await CustomCacheManager.loadJsonCache(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        final cachedList = cached
            .map((e) => ImageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        print('📦 Loaded ${cachedList.length} cached products');
        yield cachedList;
      } else {
        print('📦 No cached data found');
      }

      // 2️⃣ Fetch fresh data from Firestore (collectionGroup)
      final snapshot = await _db.collectionGroup('products').get();
      final freshList = snapshot.docs.map((doc) => ImageModel.fromFirestore(doc)).toList();

      // 3️⃣ Filter out deleted / inactive users
      final filteredDocs = await _filterOutDeletedUsers(snapshot.docs);
      final filteredList = filteredDocs.map(ImageModel.fromFirestore).toList();

      print('🔥 Firestore fetched ${filteredList.length} active products');

      // 4️⃣ Save fresh data to cache
      await CustomCacheManager.saveJsonCache(
        cacheKey,
        filteredList.map((e) => e.toJson()).toList(),
      );

      // 5️⃣ Emit updated data
      yield filteredList;
    } catch (e, st) {
      print('❌ getImages() failed: $e');
      print(st);
      yield [];
    }
  }


  bool get hasMore => _hasMore;
  bool get isFetching => _isFetching;

  void _startFirestoreStream() {
    final query = _buildBaseQuery().limit(_limit);
    _streamSubscription = query.snapshots().listen(
          (snapshot) => _handleFirestoreSnapshot(snapshot),
      onError: (e) => _handleStreamError(e),
    );
  }

  Query _buildBaseQuery() {
    return _db
        .collectionGroup('products')
        .where('Product.isActive', isEqualTo: true)
        .where('Product.isSoldOut', isEqualTo: false)
        .where('Product.isDeleted', isEqualTo: false)
        .orderBy('media.timestamp', descending: true);
  }



  // 🔒 Filter out products from deleted or pending-deletion users
  Future<List<QueryDocumentSnapshot>> _filterOutDeletedUsers(List<QueryDocumentSnapshot> docs) async {
    final ownerIds = <String>{};
    final ownerMap = <String, List<QueryDocumentSnapshot>>{};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final productData = data['Product'] as Map<String, dynamic>? ?? {};
      final ownerId = (productData['ownerId'] ?? productData['uid'])?.toString();
      if (ownerId == null || ownerId.isEmpty) continue;
      ownerIds.add(ownerId);
      ownerMap.putIfAbsent(ownerId, () => []).add(doc);
    }

    final allowed = <QueryDocumentSnapshot>[];

    for (var i = 0; i < ownerIds.length; i += 10) {
      final batch = ownerIds.skip(i).take(10).toList();
      final qs = await _db.collection('users').where(FieldPath.documentId, whereIn: batch).get();
      final userMap = {for (final d in qs.docs) d.id: d.data()};
      for (final id in batch) {
        final data = userMap[id];
        final docsForOwner = ownerMap[id] ?? [];
        if (data == null) {
          allowed.addAll(docsForOwner);
        } else {
          final deleted = data['isDeleted'] == true;
          final pending = data['deletionPending'] == true;
          if (!deleted && !pending) allowed.addAll(docsForOwner);
        }
      }
    }
    return allowed;
  }




  Future<void> _handleFirestoreSnapshot(QuerySnapshot snapshot) async {
    if (_isFetching) return;
    try {
      // 🔹 Get all allowed user documents
      final filteredDocs = await _filterOutDeletedUsers(snapshot.docs);

      // 🔹 IDs of allowed docs (non-deleted users)
      final allowedIds = filteredDocs.map((d) => d.id).toSet();

      for (final change in snapshot.docChanges) {
        final doc = change.doc;
        final id = doc.id;
        final isAllowed = allowedIds.contains(id);

        switch (change.type) {
          case DocumentChangeType.added:
            if (isAllowed && !_images.any((img) => img.id == id)) {
              _images.insert(0, ImageModel.fromFirestore(doc));
            }
            break;

          case DocumentChangeType.modified:
            final i = _images.indexWhere((img) => img.id == id);
            if (isAllowed) {
              // 🔹 Update or restore if user recovered
              final updated = ImageModel.fromFirestore(doc);
              if (i == -1) {
                _images.insert(0, updated);
              } else {
                _images[i] = updated;
              }
            } else if (i != -1) {
              // 🔹 User got deleted — remove their product
              _images.removeAt(i);
            }
            break;

          case DocumentChangeType.removed:
            _images.removeWhere((img) => img.id == id);
            break;
        }
      }

      await _saveImagesToCache();
      _emitImages();
    } catch (e) {
      _imagesStreamController.addError('Error processing snapshot: $e');
    }
  }




  void _handleStreamError(dynamic error) {
    _imagesStreamController.addError('Connection error: $error');
    Timer(const Duration(seconds: 5), () {
      if (!_imagesStreamController.isClosed) _startFirestoreStream();
    });
  }

  void _updateImagesFromSnapshot(QuerySnapshot snapshot) {
    _images
      ..clear()
      ..addAll(snapshot.docs.map(ImageModel.fromFirestore));
    if (snapshot.docs.isNotEmpty) _lastDocument = snapshot.docs.last;
    _hasMore = snapshot.docs.length == _limit;
  }

  void _mergeStreamChanges(QuerySnapshot snapshot) {
    for (final change in snapshot.docChanges) {
      final doc = change.doc;
      switch (change.type) {
        case DocumentChangeType.added:
          if (!_images.any((img) => img.id == doc.id)) {
            _images.insert(0, ImageModel.fromFirestore(doc));
          }
          break;
        case DocumentChangeType.modified:
          final i = _images.indexWhere((img) => img.id == doc.id);
          if (i != -1) _images[i] = ImageModel.fromFirestore(doc);
          break;
        case DocumentChangeType.removed:
          _images.removeWhere((img) => img.id == doc.id);
          break;
      }
    }
  }

  // ---------------- Cache ----------------
  Future<void> _loadCachedImages() async {
    try {
      final cachedList = await CustomCacheManager.loadJsonCache(_cacheKey);
      if (cachedList != null && cachedList.isNotEmpty) {
        _images
          ..clear()
          ..addAll(cachedList.map((e) => ImageModel.fromJson(e)));
        _emitImages();
      }
    } catch (e) {
      await CustomCacheManager.clearJsonCache(_cacheKey);
      _images.clear();
    }
  }

  Future<void> _saveImagesToCache() async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () async {
      final encodedList = _images.map((image) => image.toJson()).toList();
      await CustomCacheManager.saveJsonCache(_cacheKey, encodedList);
    });
  }

  Future<void> _clearCache() async {
    await CustomCacheManager.clearJsonCache(_cacheKey);
  }


  void _emitImages() {
    if (!_imagesStreamController.isClosed) {
      _imagesStreamController.add(List.from(_images));
    }
  }

  // ---------------- Pagination ----------------
  Future<void> fetchMoreImages() async {
    if (!_hasMore || _isFetching) return;
    _isFetching = true;
    try {
      var query = _buildBaseQuery().limit(_limit);
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        // 🔒 Filter out deleted or pending users
        final filtered = await _filterOutDeletedUsers(snapshot.docs);

        if (filtered.isNotEmpty) {
          _lastDocument = filtered.last;
          _images.addAll(filtered.map(ImageModel.fromFirestore));
          _hasMore = filtered.length == _limit;
          await _saveImagesToCache();
          _emitImages();
        } else {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _imagesStreamController.addError('Pagination failed: $e');
    } finally {
      _isFetching = false;
    }
  }


  Future<void> refreshImages() async {
    if (_isFetching) return;
    _isFetching = true;
    print('🔄 Refreshing product list...');

    try {
      final snapshot = await _buildBaseQuery().limit(_limit).get();
      final filtered = await _filterOutDeletedUsers(snapshot.docs);

      if (filtered.isNotEmpty) {
        _images
          ..clear()
          ..addAll(filtered.map(ImageModel.fromFirestore));

        _lastDocument = filtered.last;
        _hasMore = filtered.length == _limit;

        await _saveImagesToCache(); // ✅ overwrite cache only if data exists
        _emitImages();
        print('✅ Refresh complete: ${_images.length} products.');
      } else {
        print('⚠️ Firestore returned empty, keeping old cache.');
      }
    } catch (e) {
      _imagesStreamController.addError('Refresh failed: $e');
      print('❌ refreshImages() failed: $e');
    } finally {
      _isFetching = false;
    }
  }



  // ---------------- Like / Unlike ----------------
  Future<void> toggleLike(DocumentReference docRef, {String? ownerId}) async {
    final uid = currentUserId;
    if (uid == null) throw Exception("User not logged in");

    if (ownerId != null && uid == ownerId) {
      throw Exception("You cannot like your own ad");
    }

    final image = _images.firstWhere(
          (img) => img.docRef?.id == docRef.id,
      orElse: () => ImageModel(id: '', docRef: null),
    );

    final isLiked = image.likedBy.contains(uid);
    if (isLiked) {
      await removeLike(docRef);
    } else {
      await addLike(docRef);
    }
  }

  Future<void> addLike(DocumentReference docRef) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      _updateLocalLikeStatus(docRef.id, uid, true);
      await docRef.update({
        'Product.likes': FieldValue.increment(1),
        'Product.likedBy': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      _updateLocalLikeStatus(docRef.id, uid, false);
    }
  }

  Future<void> removeLike(DocumentReference docRef) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      final snapshot = await docRef.get();
      final data = snapshot.data() as Map<String, dynamic>? ?? {};
      final product = (data['Product'] ?? {}) as Map<String, dynamic>;
      final currentLikes = (product['likes'] ?? 0) as num;

      if (currentLikes > 0) {
        _updateLocalLikeStatus(docRef.id, uid, false);
        await docRef.update({
          'Product.likes': FieldValue.increment(-1),
          'Product.likedBy': FieldValue.arrayRemove([uid]),
        });
      } else {
        _updateLocalLikeStatus(docRef.id, uid, false);
        await docRef.update({
          'Product.likedBy': FieldValue.arrayRemove([uid]),
        });
      }
    } catch (e) {
      _updateLocalLikeStatus(docRef.id, uid, true);
    }
  }

  void _updateLocalLikeStatus(String docId, String uid, bool isLiked) {
    final i = _images.indexWhere((img) => img.id == docId);
    if (i != -1) {
      final current = _images[i];
      final newLikedBy = List<String>.from(current.likedBy);

      if (isLiked) {
        if (!newLikedBy.contains(uid)) newLikedBy.add(uid);
      } else {
        newLikedBy.remove(uid);
      }

      final safeCount = max(0, newLikedBy.length);

      _images[i] = current.copyWith(
        likeCount: safeCount,
        likedBy: newLikedBy,
      );

      _emitImages();
      _saveImagesToCache();
    }
  }

  // ---------------- Helper Queries ----------------
  Stream<List<ImageModel>> getImagesByCategory(String category) async* {
    final snapStream = _buildBaseQuery()
        .where('MainCategory.category', isEqualTo: category)
        .snapshots();

    await for (final snap in snapStream) {
      final filteredDocs = await _filterOutDeletedUsers(snap.docs);
      yield filteredDocs.map(ImageModel.fromFirestore).toList();
    }
  }


  Stream<List<ImageModel>> getUserProducts(String userId) async* {
    final userSnap = await _db.collection('users').doc(userId).get();
    final userData = userSnap.data() ?? {};
    if (userData['isDeleted'] == true || userData['deletionPending'] == true) {
      yield [];
      return;
    }

    final snapStream =
    _db.collection('users').doc(userId).collection('products').snapshots();

    await for (final snap in snapStream) {
      final filteredDocs = await _filterOutDeletedUsers(snap.docs);
      yield filteredDocs.map(ImageModel.fromFirestore).toList();
    }
  }

  Stream<List<ImageModel>> getLikedImages() {
    final uid = currentUserId;
    if (uid == null) return Stream.value([]);
    return _db
        .collectionGroup('products')
        .where('Product.likedBy', arrayContains: uid)
        .where('Product.isActive', isEqualTo: true)
        .where('Product.isSoldOut', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.map(ImageModel.fromFirestore).toList());
  }

  List<ImageModel> filterImages({
    String? location,
    List<String>? keywords,
    Map<String, String>? filters,
    String? sortOption,
  }) {
    var list = List<ImageModel>.from(_images);

    if (location?.isNotEmpty == true) {
      final loc = location!.toLowerCase();
      list = list.where((img) =>
      (img.city ?? '').toLowerCase().contains(loc) ||
          (img.state ?? '').toLowerCase().contains(loc)).toList();
    }

    if (keywords != null && keywords.isNotEmpty) {
      list = list.where((img) {
        final cat = (img.category).toLowerCase();
        final sub = (img.subcategory).toLowerCase();
        return keywords.any((kw) =>
        cat.contains(kw.toLowerCase()) || sub.contains(kw.toLowerCase()));
      }).toList();
    }

    if (filters != null) {
      if (filters.containsKey('minPrice') || filters.containsKey('maxPrice')) {
        final min = double.tryParse(filters['minPrice'] ?? '0') ?? 0;
        final max = double.tryParse(filters['maxPrice'] ?? '999999999') ??
            double.infinity;
        list = list.where((img) {
          final price = double.tryParse(img.price ?? '0') ?? 0;
          return price >= min && price <= max;
        }).toList();
      }

      for (final entry in filters.entries) {
        if (entry.key == 'minPrice' || entry.key == 'maxPrice') continue;
        list = list.where((img) {
          final value = img.productDetails?[entry.key]?.toString() ?? '';
          return value == entry.value;
        }).toList();
      }
    }

    if (sortOption != null) {
      switch (sortOption) {
        case 'Price: High to Low':
          list.sort((a, b) => (double.tryParse(b.price ?? '0') ?? 0)
              .compareTo(double.tryParse(a.price ?? '0') ?? 0));
          break;
        case 'Price: Low to High':
          list.sort((a, b) => (double.tryParse(a.price ?? '0') ?? 0)
              .compareTo(double.tryParse(b.price ?? '0') ?? 0));
          break;
        case 'Newest First':
          list.sort((a, b) => (b.time ?? DateTime(0))
              .compareTo(a.time ?? DateTime(0)));
          break;
        case 'Oldest First':
          list.sort((a, b) => (a.time ?? DateTime(0))
              .compareTo(b.time ?? DateTime(0)));
          break;
      }
    }

    return list;
  }

  Future<void> dispose() async {
    try {
      await _streamSubscription?.cancel();
      _debounceTimer?.cancel();
      await _imagesStreamController.close();
    } catch (e) {
      debugPrint('⚠️ DataService dispose error: $e');
    } finally {
      _instance = null;
    }
  }
}
