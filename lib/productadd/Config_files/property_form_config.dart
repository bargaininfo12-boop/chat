// File: property_form_config.dart
// Version: 2.0.0
// Dynamic config for Property listings
// Supports Whole Property or Part/Portion sale
// Custom field sets per subcategory

List<Map<String, dynamic>> getPropertyFormConfig(String subcategory) {
  // 🧠 Property-type-based field mapping
  final Map<String, List<Map<String, dynamic>>> propertyFieldMap = {
    'Residential': [
      {'label': 'Bedrooms', 'type': 'number'},
      {'label': 'Bathrooms', 'type': 'number'},
      {
        'label': 'Furnishing',
        'type': 'dropdown',
        'options': ['Furnished', 'Semi-Furnished', 'Unfurnished'],
      },
      {
        'label': 'Construction Status',
        'type': 'dropdown',
        'options': ['New Launch', 'Ready to Move', 'Under Construction'],
      },
    ],
    'Commercial': [
      {'label': 'Office Name / Building', 'type': 'text'},
      {'label': 'Floor No', 'type': 'number'},
      {'label': 'Total Floors', 'type': 'number'},
      {
        'label': 'Furnishing',
        'type': 'dropdown',
        'options': ['Furnished', 'Semi-Furnished', 'Unfurnished'],
      },
    ],
    'Office': [
      {'label': 'Office Type', 'type': 'dropdown', 'options': ['Cabin', 'Shared', 'Entire Floor', 'Other']},
      {'label': 'Carpet Area (sqft)', 'type': 'number'},
      {'label': 'Floor No', 'type': 'number'},
      {'label': 'Total Floors', 'type': 'number'},
    ],
    'Land': [
      {'label': 'Plot Area (sqft)', 'type': 'number'},
      {'label': 'Plot Facing', 'type': 'dropdown', 'options': ['East', 'West', 'North', 'South']},
      {
        'label': 'Ownership Type',
        'type': 'dropdown',
        'options': ['Freehold', 'Leasehold', 'Co-operative'],
      },
    ],
    'Other': [
      {'label': 'Area (sqft)', 'type': 'number'},
    ],
  };

  final List<Map<String, dynamic>> subFields =
      propertyFieldMap[subcategory] ?? propertyFieldMap['Other']!;

  return [
    // 🧱 Selling Type
    {
      'label': 'Selling Type',
      'type': 'dropdown',
      'options': ['Whole Property', 'Part/Portion'],
      'default': 'Whole Property',
    },

    // 🧩 Portion specific fields
    {
      'label': 'Portion Type',
      'type': 'dropdown',
      'options': ['1 Room', '1 BHK', '2 BHK', 'Shop Space', 'Floor Portion', 'Other'],
      'dependsOn': {'label': 'Selling Type', 'value': 'Part/Portion'},
    },
    {
      'label': 'Area (sqft)',
      'type': 'number',
      'dependsOn': {'label': 'Selling Type', 'value': 'Part/Portion'},
    },

    // 🏠 General property info
    {
      'label': 'Property Type',
      'type': 'dropdown',
      'options': ['Residential', 'Commercial', 'Office', 'Land'],
    },
    {'label': 'Locality', 'type': 'text'},
    {'label': 'Project Name', 'type': 'text'},
    {
      'label': 'Listed By',
      'type': 'dropdown',
      'options': ['Owner', 'Agent', 'Builder'],
    },

    // 🏗️ Subcategory-specific dynamic fields
    ...subFields,

    // 🚗 Common attributes
    {
      'label': 'Car Parking',
      'type': 'dropdown',
      'options': ['Covered', 'Open', 'None'],
    },
    {
      'label': 'Facing',
      'type': 'dropdown',
      'options': [
        'East',
        'West',
        'North',
        'South',
        'North-East',
        'North-West',
        'South-East',
        'South-West'
      ],
    },
    {'label': 'Total Floors', 'type': 'number'},
    {'label': 'Floor No', 'type': 'number'},

    // 🧾 Description
    {'label': 'Description', 'type': 'description'},
  ];
}
