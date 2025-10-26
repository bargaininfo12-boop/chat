// File: lib/Location/location_models.dart
// Simple clean version without extra features

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

// Generic API response wrapper
class ApiResponse<T> {
  final T? data;
  final String? errorMessage;
  final int? statusCode;
  final DateTime timestamp;

  ApiResponse.success(this.data)
      : errorMessage = null,
        statusCode = 200,
        timestamp = DateTime.now();

  ApiResponse.failure(this.errorMessage, {this.statusCode})
      : data = null,
        timestamp = DateTime.now();

  bool get isSuccess => errorMessage == null && data != null;
  bool get isFailure => !isSuccess;

  T getDataOrElse(T fallback) => data ?? fallback;

  ApiResponse<U> map<U>(U Function(T) transform) {
    if (isSuccess) {
      try {
        return ApiResponse.success(transform(data as T));
      } catch (e) {
        return ApiResponse.failure('Error transforming data: $e');
      }
    } else {
      return ApiResponse.failure(errorMessage, statusCode: statusCode);
    }
  }
}

// Place suggestion model
class PlaceSuggestion extends Equatable {
  final String description;
  final String placeId;
  final String? mainText;
  final String? secondaryText;
  final List<String> types;
  final int distanceMeters;

  const PlaceSuggestion({
    required this.description,
    required this.placeId,
    this.mainText,
    this.secondaryText,
    this.types = const [],
    this.distanceMeters = 0,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) {
    try {
      final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;

      return PlaceSuggestion(
        description: json['description'] as String? ?? '',
        placeId: json['place_id'] as String? ?? '',
        mainText: structuredFormatting?['main_text'] as String?,
        secondaryText: structuredFormatting?['secondary_text'] as String?,
        types: (json['types'] as List?)?.cast<String>() ?? [],
        distanceMeters: json['distance_meters'] as int? ?? 0,
      );
    } catch (e) {
      throw FormatException('Invalid PlaceSuggestion JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'place_id': placeId,
      'main_text': mainText,
      'secondary_text': secondaryText,
      'types': types,
      'distance_meters': distanceMeters,
    };
  }

  String get displayText => mainText ?? description;
  String get subtitle => secondaryText ?? '';

  @override
  List<Object?> get props => [description, placeId, mainText, secondaryText, types, distanceMeters];
}

// Place details model
class PlaceDetails extends Equatable {
  final LatLng coordinates;
  final String address;
  final String? name;
  final String? phoneNumber;
  final String? website;
  final double? rating;
  final List<String> types;
  final String? vicinity;
  final PlaceGeometry? geometry;

  const PlaceDetails({
    required this.coordinates,
    required this.address,
    this.name,
    this.phoneNumber,
    this.website,
    this.rating,
    this.types = const [],
    this.vicinity,
    this.geometry,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    try {
      final result = json['result'] as Map<String, dynamic>;
      final location = result['geometry']['location'] as Map<String, dynamic>;

      return PlaceDetails(
        coordinates: LatLng(
          (location['lat'] as num).toDouble(),
          (location['lng'] as num).toDouble(),
        ),
        address: result['formatted_address'] as String? ?? '',
        name: result['name'] as String?,
        phoneNumber: result['formatted_phone_number'] as String?,
        website: result['website'] as String?,
        rating: (result['rating'] as num?)?.toDouble(),
        types: (result['types'] as List?)?.cast<String>() ?? [],
        vicinity: result['vicinity'] as String?,
        geometry: result['geometry'] != null
            ? PlaceGeometry.fromJson(result['geometry'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      throw FormatException('Invalid PlaceDetails JSON: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'address': address,
      'name': name,
      'phone_number': phoneNumber,
      'website': website,
      'rating': rating,
      'types': types,
      'vicinity': vicinity,
      'geometry': geometry?.toJson(),
    };
  }

  String get displayName => name ?? address;
  bool get hasRating => rating != null && rating! > 0;

  @override
  List<Object?> get props => [
    coordinates, address, name, phoneNumber,
    website, rating, types, vicinity, geometry
  ];
}

// Place geometry information
class PlaceGeometry extends Equatable {
  final LatLng location;
  final PlaceBounds? viewport;
  final String locationType;

  const PlaceGeometry({
    required this.location,
    this.viewport,
    this.locationType = 'APPROXIMATE',
  });

  factory PlaceGeometry.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>;

    return PlaceGeometry(
      location: LatLng(
        (location['lat'] as num).toDouble(),
        (location['lng'] as num).toDouble(),
      ),
      viewport: json['viewport'] != null
          ? PlaceBounds.fromJson(json['viewport'] as Map<String, dynamic>)
          : null,
      locationType: json['location_type'] as String? ?? 'APPROXIMATE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
      },
      'viewport': viewport?.toJson(),
      'location_type': locationType,
    };
  }

  @override
  List<Object?> get props => [location, viewport, locationType];
}

// Place bounds for viewport
class PlaceBounds extends Equatable {
  final LatLng northeast;
  final LatLng southwest;

  const PlaceBounds({
    required this.northeast,
    required this.southwest,
  });

  factory PlaceBounds.fromJson(Map<String, dynamic> json) {
    final ne = json['northeast'] as Map<String, dynamic>;
    final sw = json['southwest'] as Map<String, dynamic>;

    return PlaceBounds(
      northeast: LatLng(
        (ne['lat'] as num).toDouble(),
        (ne['lng'] as num).toDouble(),
      ),
      southwest: LatLng(
        (sw['lat'] as num).toDouble(),
        (sw['lng'] as num).toDouble(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'northeast': {
        'lat': northeast.latitude,
        'lng': northeast.longitude,
      },
      'southwest': {
        'lat': southwest.latitude,
        'lng': southwest.longitude,
      },
    };
  }

  @override
  List<Object> get props => [northeast, southwest];
}

// Location data model
class LocationData extends Equatable {
  final Position position;
  final String address;
  final String state;
  final String city;
  final String pinCode;
  final String country;
  final DateTime timestamp;
  final double accuracy;

  const LocationData({
    required this.position,
    required this.address,
    required this.state,
    required this.city,
    required this.pinCode,
    this.country = 'India',
    required this.timestamp,
    required this.accuracy,
  });

  factory LocationData.fromPosition(
      Position position,
      Map<String, String> addressDetails,
      ) {
    return LocationData(
      position: position,
      address: addressDetails['address'] ?? '',
      state: addressDetails['state'] ?? '',
      city: addressDetails['city'] ?? '',
      pinCode: addressDetails['pinCode'] ?? '',
      country: addressDetails['country'] ?? 'India',
      timestamp: position.timestamp ?? DateTime.now(),
      accuracy: position.accuracy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'address': address,
      'state': state,
      'city': city,
      'pinCode': pinCode,
      'country': country,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'accuracy': accuracy,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'location': {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'state': state,
        'city': city,
        'pinCode': pinCode,
        'country': country,
        'timestamp': timestamp,
        'accuracy': accuracy,
      },
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      position: Position(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
        accuracy: (json['accuracy'] as num).toDouble(),
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      ),
      address: json['address'] as String? ?? '',
      state: json['state'] as String? ?? '',
      city: json['city'] as String? ?? '',
      pinCode: json['pinCode'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }

  LatLng get coordinates => LatLng(position.latitude, position.longitude);
  bool get isAccurate => accuracy <= 100;
  bool get isRecent => DateTime.now().difference(timestamp).inMinutes < 30;

  LocationData copyWith({
    Position? position,
    String? address,
    String? state,
    String? city,
    String? pinCode,
    String? country,
    DateTime? timestamp,
    double? accuracy,
  }) {
    return LocationData(
      position: position ?? this.position,
      address: address ?? this.address,
      state: state ?? this.state,
      city: city ?? this.city,
      pinCode: pinCode ?? this.pinCode,
      country: country ?? this.country,
      timestamp: timestamp ?? this.timestamp,
      accuracy: accuracy ?? this.accuracy,
    );
  }

  @override
  List<Object> get props => [
    position.latitude, position.longitude, address, state,
    city, pinCode, country, timestamp, accuracy
  ];
}

// Location service configuration
class LocationServiceConfig extends Equatable {
  final LocationAccuracy accuracy;
  final int distanceFilter;
  final Duration timeout;
  final Duration cacheExpiry;
  final bool enableCache;

  const LocationServiceConfig({
    this.accuracy = LocationAccuracy.high,
    this.distanceFilter = 10,
    this.timeout = const Duration(seconds: 30),
    this.cacheExpiry = const Duration(minutes: 5),
    this.enableCache = true,
  });

  LocationServiceConfig copyWith({
    LocationAccuracy? accuracy,
    int? distanceFilter,
    Duration? timeout,
    Duration? cacheExpiry,
    bool? enableCache,
  }) {
    return LocationServiceConfig(
      accuracy: accuracy ?? this.accuracy,
      distanceFilter: distanceFilter ?? this.distanceFilter,
      timeout: timeout ?? this.timeout,
      cacheExpiry: cacheExpiry ?? this.cacheExpiry,
      enableCache: enableCache ?? this.enableCache,
    );
  }

  @override
  List<Object> get props => [accuracy, distanceFilter, timeout, cacheExpiry, enableCache];
}
