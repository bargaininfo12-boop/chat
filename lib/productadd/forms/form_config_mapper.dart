// File: form_config_mapper.dart

import 'package:bargain/productadd/Config_files/electronics_form_config.dart';
import 'package:bargain/productadd/Config_files/mobile_form_config.dart';
import 'package:bargain/productadd/Config_files/property_form_config.dart';
import 'package:bargain/productadd/Config_files/vehicle_form_config.dart';
import 'package:bargain/productadd/Config_files/furniture_form_config.dart';
import 'package:bargain/productadd/Config_files/books_form_config.dart';
// ✅ Add new category imports here if needed

/// Maps top-level categories to their correct dynamic form configuration.
/// Electronics now uses [getElectronicsFormConfig] so subcategories (like TV, AC)
/// can dynamically load the right spare-part options.
class FormConfigMapper {
  static List<Map<String, dynamic>> getFormConfig(
      String category, {
        String? subcategory,
      }) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return getElectronicsFormConfig(subcategory ?? 'Other');
      case 'mobiles':
        return getMobileFormConfig(subcategory ?? 'Other');
      case 'vehicles':
        return getVehicleFormConfig(subcategory ?? 'Other');
      case 'properties':
        return getPropertyFormConfig(subcategory ?? 'Other');
      case 'furniture':
        return getFurnitureFormConfig(subcategory ?? 'Other');
      case 'books':
        return getBooksFormConfig(subcategory ?? 'Other');
      default:
        return [];
    }
  }
}
