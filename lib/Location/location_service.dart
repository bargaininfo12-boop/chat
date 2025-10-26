// File: lib/Location/location_service.dart
// Simple clean version without extra features - Bug Fixed

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'location_models.dart';

class LocationService {
  static const String _placesBaseUrl = 'https://maps.googleapis.com/maps/api/place';
  static final Logger _logger = Logger();
  static final String _apiKey = const String.fromEnvironment('PLACES_API_KEY');

  // Cache and HTTP client
  static final Map<String, _CachedResult> _cache = {};
  static final http.Client _httpClient = http.Client();

  // Connectivity monitoring
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static bool _isOnline = true;

  // Configuration
  static const int _cacheExpiryMinutes = 5;
  static const int _maxCacheSize = 50;
  static const Duration _defaultTimeout = Duration(seconds: 15);

  // Initialize service
  static void initialize() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    });
  }

  // Clean up resources
  static void dispose() {
    _connectivitySubscription?.cancel();
    _httpClient.close();
    _cache.clear();
  }

  // Generic API call with caching
  static Future<ApiResponse<Map<String, dynamic>>> _apiCall(String endpoint) async {
    // Check cache first
    final cached = _getCachedResult(endpoint);
    if (cached != null) return ApiResponse.success(cached);

    // Check connectivity
    if (!_isOnline) {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.none)) {
        return ApiResponse.failure("You are offline. Please check your internet connection.");
      }
      _isOnline = true;
    }

    if (_apiKey.isEmpty) {
      return ApiResponse.failure('PLACES_API_KEY is not defined.');
    }

    try {
      final url = Uri.parse('$_placesBaseUrl$endpoint&key=$_apiKey');
      final response = await _httpClient.get(url).timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (data['status'] == 'OK') {
          _setCachedResult(endpoint, data);
          return ApiResponse.success(data);
        }

        return ApiResponse.failure(_getErrorMessage(data));
      } else {
        return ApiResponse.failure('Network Error: ${response.statusCode}');
      }
    } on SocketException {
      return ApiResponse.failure('No internet connection.');
    } on TimeoutException {
      return ApiResponse.failure('Request timed out.');
    } catch (e) {
      _logger.e('API Error', error: e);
      return ApiResponse.failure('Unexpected error: $e');
    }
  }

  // Cache management
  static Map<String, dynamic>? _getCachedResult(String key) {
    final cached = _cache[key];
    if (cached != null && cached.isValid) {
      return cached.data;
    }
    _cache.remove(key);
    return null;
  }

  static void _setCachedResult(String key, Map<String, dynamic> data) {
    _cache[key] = _CachedResult(data);
    if (_cache.length > _maxCacheSize) {
      _cleanOldCache();
    }
  }

  static void _cleanOldCache() {
    _cache.removeWhere((key, value) => !value.isValid);
  }

  // Error message helper
  static String _getErrorMessage(Map<String, dynamic> data) {
    final status = data['status'] as String;
    switch (status) {
      case 'ZERO_RESULTS': return 'No results found.';
      case 'OVER_QUERY_LIMIT': return 'Search quota exceeded.';
      case 'REQUEST_DENIED': return 'Request denied.';
      case 'INVALID_REQUEST': return 'Invalid request.';
      default: return data['error_message'] ?? 'API Error: $status';
    }
  }

  // Get place suggestions
  static Future<ApiResponse<List<PlaceSuggestion>>> getPlaceSuggestions(String input) async {
    if (input.trim().length < 2) return ApiResponse.success([]);

    final sanitizedInput = Uri.encodeQueryComponent(input.trim());
    final result = await _apiCall('/autocomplete/json?input=$sanitizedInput&components=country:in');

    if (result.isSuccess) {
      try {
        final predictions = result.data!['predictions'] as List? ?? [];
        final suggestions = predictions
            .map((p) => PlaceSuggestion.fromJson(p as Map<String, dynamic>))
            .toList();
        return ApiResponse.success(suggestions);
      } catch (e) {
        return ApiResponse.failure('Error processing suggestions.');
      }
    }

    return ApiResponse.failure(result.errorMessage);
  }

  // Get place details
  static Future<ApiResponse<PlaceDetails>> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return ApiResponse.failure('Invalid place ID.');

    final result = await _apiCall('/details/json?place_id=$placeId&fields=geometry,formatted_address,name,formatted_phone_number,website,rating,types,vicinity');

    if (result.isSuccess) {
      try {
        return ApiResponse.success(PlaceDetails.fromJson(result.data!));
      } catch (e) {
        return ApiResponse.failure('Error processing place details.');
      }
    }

    return ApiResponse.failure(result.errorMessage);
  }

  // Get address from coordinates - Fixed version
  static Future<AddressResult> getAddressFromCoordinates(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return AddressResult.failure('No address found for this location.');
      }

      final place = placemarks.first;
      final addressParts = _extractAddressParts(place);

      return AddressResult.success(
        address: addressParts.join(', '),
        state: _cleanString(place.administrativeArea) ?? '',
        city: _cleanString(place.locality) ?? _cleanString(place.subAdministrativeArea) ?? '',
        pinCode: _cleanString(place.postalCode) ?? '',
        country: _cleanString(place.country) ?? 'India',
      );
    } catch (e) {
      _logger.e('Geocoding error', error: e);
      return AddressResult.failure('Could not get address: ${e.toString()}');
    }
  }

  // Extract clean address parts - Improved version
  static List<String> _extractAddressParts(Placemark place) {
    final potentialParts = [
      place.subThoroughfare, // house number
      place.thoroughfare,    // street name
      place.subLocality,     // area
      place.locality,        // city
      place.subAdministrativeArea, // district
      place.administrativeArea,    // state
    ];

    final cleanParts = <String>[];
    final seenParts = <String>{};

    for (final part in potentialParts) {
      final cleaned = _cleanString(part);
      if (cleaned != null &&
          cleaned.length > 1 &&
          !seenParts.contains(cleaned.toLowerCase()) &&
          !_isInvalidAddressPart(cleaned)) {
        cleanParts.add(cleaned);
        seenParts.add(cleaned.toLowerCase());
      }
    }

    // If we don't have enough parts, add postal code and country
    if (cleanParts.length < 3) {
      final postalCode = _cleanString(place.postalCode);
      if (postalCode != null && !seenParts.contains(postalCode.toLowerCase())) {
        cleanParts.add(postalCode);
      }
    }

    return cleanParts;
  }

  // Helper method to clean strings
  static String? _cleanString(String? input) {
    if (input == null || input.isEmpty) return null;
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Helper method to check invalid address parts
  static bool _isInvalidAddressPart(String part) {
    final invalid = ['unnamed', 'unknown', '+', '++'];
    return invalid.any((invalid) =>
        part.toLowerCase().contains(invalid.toLowerCase()));
  }

  // Store location in Firestore
  static Future<bool> storeLocation(LocationData locationData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logger.w('No authenticated user found');
        return false;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(locationData.toFirestoreMap(), SetOptions(merge: true));

      _logger.i('Location stored successfully');
      return true;
    } catch (e) {
      _logger.e('Error storing location', error: e);
      return false;
    }
  }

  // Check and request location permission - Improved
  static Future<LocationPermissionResult> checkLocationPermission() async {
    try {
      // Check if location services are enabled first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult(
          granted: false,
          message: 'Location services are disabled. Please enable them in settings.',
          openSettings: true,
        );
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationPermissionResult(
            granted: false,
            message: 'Location permission denied.',
            canRetry: true,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionResult(
          granted: false,
          message: 'Location permission permanently denied. Please enable in settings.',
          openSettings: true,
        );
      }

      return LocationPermissionResult(
        granted: true,
        message: 'Location permission granted.',
      );
    } catch (e) {
      _logger.e('Error checking location permission', error: e);
      return LocationPermissionResult(
        granted: false,
        message: 'Error checking permissions: $e',
      );
    }
  }

  // Get current location - Improved with better error handling
  static Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      final settings = LocationSettings(
        accuracy: accuracy,
        distanceFilter: 10,
        timeLimit: timeout,
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      ).timeout(timeout);

      if (_isValidPosition(position)) {
        _logger.i('Current location obtained: ${position.latitude}, ${position.longitude}');
        return position;
      } else {
        _logger.w('Invalid position received');
        return null;
      }
    } on TimeoutException {
      _logger.e('Location timeout');
      return null;
    } on LocationServiceDisabledException {
      _logger.e('Location services disabled');
      return null;
    } on PermissionDeniedException {
      _logger.e('Location permission denied');
      return null;
    } catch (e) {
      _logger.e('Error getting current location', error: e);
      return null;
    }
  }

  // Get last known location
  static Future<Position?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null && _isValidPosition(position)) {
        _logger.i('Last known location: ${position.latitude}, ${position.longitude}');
        return position;
      }
      return null;
    } catch (e) {
      _logger.e('Error getting last known location', error: e);
      return null;
    }
  }

  // Get full location data - Main method for getting complete location info
  static Future<ApiResponse<LocationData>> getFullLocationData({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = _defaultTimeout,
    bool useLastKnown = true,
  }) async {
    try {
      // Check permissions first
      final permissionResult = await checkLocationPermission();
      if (!permissionResult.granted) {
        return ApiResponse.failure(permissionResult.message);
      }

      Position? position;

      // Try to get current location
      position = await getCurrentLocation(accuracy: accuracy, timeout: timeout);

      // If current location fails and useLastKnown is true, try last known
      if (position == null && useLastKnown) {
        position = await getLastKnownLocation();
        if (position != null) {
          _logger.i('Using last known location');
        }
      }

      if (position == null) {
        return ApiResponse.failure('Unable to determine location. Please try again.');
      }

      // Get address details
      final addressResult = await getAddressFromCoordinates(position);
      if (!addressResult.isSuccess) {
        return ApiResponse.failure(addressResult.errorMessage);
      }

      // Create location data
      final locationData = LocationData.fromPosition(position, addressResult.toMap());

      // Try to store in Firestore (don't fail if this fails)
      try {
        await storeLocation(locationData);
      } catch (e) {
        _logger.w('Failed to store location in Firestore', error: e);
        // Continue without failing
      }

      return ApiResponse.success(locationData);
    } catch (e) {
      _logger.e('Error getting full location data', error: e);
      return ApiResponse.failure('Error getting location: ${e.toString()}');
    }
  }

  // Validate position
  static bool _isValidPosition(Position position) {
    return position.latitude.abs() <= 90 &&
        position.longitude.abs() <= 180 &&
        position.accuracy > 0 &&
        position.accuracy < 10000; // Reject very inaccurate positions
  }

  // Calculate distance between positions
  static double calculateDistance(Position pos1, Position pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude, pos1.longitude,
      pos2.latitude, pos2.longitude,
    );
  }

  // Clear cache
  static void clearCache() {
    _cache.clear();
    _logger.i('Cache cleared');
  }

  // Check if location is in India (optional validation)
  static bool isLocationInIndia(Position position) {
    // Rough bounds for India
    return position.latitude >= 6.0 && position.latitude <= 37.0 &&
        position.longitude >= 68.0 && position.longitude <= 97.0;
  }
}

// Private helper classes
class _CachedResult {
  final Map<String, dynamic> data;
  final DateTime timestamp;

  _CachedResult(this.data) : timestamp = DateTime.now();

  bool get isValid => DateTime.now().difference(timestamp).inMinutes < 5;
}

// Result classes
class AddressResult {
  final bool isSuccess;
  final String? address;
  final String? state;
  final String? city;
  final String? pinCode;
  final String? country;
  final String? errorMessage;

  AddressResult.success({
    required this.address,
    required this.state,
    required this.city,
    required this.pinCode,
    required this.country,
  }) : isSuccess = true, errorMessage = null;

  AddressResult.failure(this.errorMessage)
      : isSuccess = false, address = null, state = null,
        city = null, pinCode = null, country = null;

  Map<String, String> toMap() {
    if (isSuccess) {
      return {
        'address': address ?? '',
        'state': state ?? '',
        'city': city ?? '',
        'pinCode': pinCode ?? '',
        'country': country ?? 'India',
      };
    }
    return {};
  }
}

class LocationPermissionResult {
  final bool granted;
  final String message;
  final bool openSettings;
  final bool canRetry;

  LocationPermissionResult({
    required this.granted,
    required this.message,
    this.openSettings = false,
    this.canRetry = false,
  });
}
