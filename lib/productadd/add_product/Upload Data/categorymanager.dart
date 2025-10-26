import 'package:bargain/productadd/cateogery/books_content.dart';
import 'package:bargain/productadd/cateogery/electronics_screen.dart';
import 'package:bargain/productadd/cateogery/furniture_content.dart';
import 'package:bargain/productadd/cateogery/mobile_content.dart';
import 'package:bargain/productadd/cateogery/properties_content.dart';
import 'package:bargain/productadd/cateogery/vehicle_content.dart';
import 'package:flutter/material.dart';

// Version: 1.0.0
// Timestamp: May 24, 2025
// Description: Singleton CategoryManager extracted from UploadBottomSheet,
// manages category data and image precaching for the app.
// Link to upload bottom sheet

class CategoryManager {
  static final CategoryManager _instance = CategoryManager._internal();

  factory CategoryManager() => _instance;

  CategoryManager._internal();

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Electronics',
      'image': 'assets/upload_Bottom/electroinc.png',
      'destination': const ElectronicsContent(),
      'color': Colors.blueAccent,
    },
    {
      'name': 'Vehicle',
      'image': 'assets/upload_Bottom/vechical.png',
      'destination': const VehicleContent(),
      'color': Colors.redAccent,
    },
    {
      'name': 'Properties',
      'image': 'assets/upload_Bottom/home_1.png',
      'destination': const PropertiesContent(),
      'color': Colors.greenAccent,
    },
    {
      'name': 'Mobile',
      'image': 'assets/upload_Bottom/Mobile.png',
      'destination': const MobileContent(),
      'color': Colors.purpleAccent,
    },
    {
      'name': 'Books',
      'image': 'assets/upload_Bottom/books.png',
      'destination': const BooksContent(),
      'color': Colors.orangeAccent,
    },
    {
      'name': 'Furniture',
      'image': 'assets/upload_Bottom/Furniture.png',
      'destination': const FurnitureContent(),
      'color': Colors.tealAccent,
    },
  ];

  void precacheImages(BuildContext context) {
    for (var category in categories) {
      precacheImage(AssetImage(category['image'] as String), context);
    }
    // Precache Pattern.png with fallback logging
    precacheImage(const AssetImage('assets/Pattern.png'), context);
  }
}
