// File: vehicle_form_config.dart
// Version: 2.0.0
// Dynamic configuration for Vehicles category
// Supports Whole Vehicle and Spare Part flows

List<Map<String, dynamic>> getVehicleFormConfig(String subcategory) {
  // 🔧 Spare parts mapped to vehicle types
  final Map<String, List<String>> sparePartsMap = {
    'Car': [
      'Engine',
      'Gearbox',
      'Tyre',
      'Headlight',
      'Battery',
      'AC Compressor',
      'Mirror',
      'Seat',
      'Other'
    ],
    'Bike': [
      'Engine',
      'Silencer',
      'Handle',
      'Wheel',
      'Brake Disc',
      'Battery',
      'Chain Kit',
      'Seat',
      'Other'
    ],
    'Scooter': [
      'Engine',
      'Tyre',
      'Headlight',
      'Battery',
      'Speedometer',
      'Mirror',
      'Seat',
      'Other'
    ],
    'Truck': [
      'Engine',
      'Tyre',
      'Battery',
      'Clutch Plate',
      'Headlight',
      'Radiator',
      'Other'
    ],
    'Bus': [
      'Engine',
      'Seat',
      'Window',
      'Tyre',
      'Mirror',
      'Compressor',
      'Other'
    ],
    'Other': ['Generic Vehicle Part', 'Tyre', 'Battery', 'Engine', 'Other'],
  };

  // 🧠 Select parts list based on current subcategory
  final List<String> spareParts =
      sparePartsMap[subcategory] ?? sparePartsMap['Other']!;

  return [
    {
      'label': 'Selling Type',
      'type': 'dropdown',
      'options': ['Whole Vehicle', 'Spare/Part'],
      'default': 'Whole Vehicle',
    },

    // 🧩 Spare Part Specific Fields
    {
      'label': 'Part Name',
      'type': 'dropdown',
      'options': spareParts,
      'dependsOn': {'label': 'Selling Type', 'value': 'Spare/Part'},
    },
    {
      'label': 'Part Condition',
      'type': 'dropdown',
      'options': ['New', 'Used - Working', 'Used - Needs Repair'],
      'dependsOn': {'label': 'Selling Type', 'value': 'Spare/Part'},
    },

    // 🚗 Standard Fields for Whole Vehicle
    {
      'label': 'Vehicle Type',
      'type': 'dropdown',
      'options': [
        'Car',
        'Bike',
        'Scooter',
        'Truck',
        'Bus',
        'Other',
      ],
    },
    {'label': 'Brand', 'type': 'text'},
    {'label': 'Model', 'type': 'text'},
    {'label': 'Year', 'type': 'year'},
    {'label': 'KM Driven', 'type': 'number'},
    {
      'label': 'Fuel Type',
      'type': 'dropdown',
      'options': ['Petrol', 'Diesel', 'Electric', 'Hybrid'],
    },
    {
      'label': 'Transmission',
      'type': 'dropdown',
      'options': ['Manual', 'Automatic'],
    },
    {
      'label': 'Ownership',
      'type': 'dropdown',
      'options': ['First Owner', 'Second Owner', 'Third Owner', 'Other'],
    },
    {
      'label': 'Condition',
      'type': 'dropdown',
      'options': ['Excellent', 'Good', 'Fair', 'Needs Repair'],
    },
    {
      'label': 'Warranty Available',
      'type': 'dropdown',
      'options': ['Yes', 'No'],
    },

    // 📝 Description
    {
      'label': 'Description',
      'type': 'description',
    },
  ];
}
