// File: mobile_form_config.dart
// Version: 1.0.0
// Form configuration for Mobiles category.
// Independent from electronics to prevent overlap.

List<Map<String, dynamic>> getMobileFormConfig(String subcategory) {
  final Map<String, List<String>> sparePartsMap = {
    'Smartphone': ['Display', 'Battery', 'Motherboard', 'Camera Module', 'Speaker', 'Other'],
    'Tablet': ['Display', 'Battery', 'Motherboard', 'Charging Port', 'Other'],
    'Smartwatch': ['Strap', 'Display', 'Battery', 'Sensor', 'Other'],
    'Earbuds': ['Charging Case', 'Earbud Piece', 'Battery', 'Other'],
    'Accessories': ['Charger', 'Cable', 'Adapter', 'Other'],
    'Feature Phone': ['Keypad', 'Display', 'Battery', 'Other'],
    'Power Bank': ['Battery Cell', 'Circuit Board', 'Other'],
    'Phone Case': ['Case Body', 'Cover Material', 'Other'],
    'Screen Protector': ['Glass Sheet', 'Other'],
    'Selfie Stick': ['Stick Body', 'Bluetooth Shutter', 'Other'],
    'Memory Card': ['Card Reader', 'Other'],
    'Portable Router': ['Battery', 'PCB Board', 'Other'],
    'Smart Speaker': ['Speaker Unit', 'Power Adapter', 'Other'],
    'Other': ['Generic Mobile Accessory', 'Other'],
  };

  final List<String> spareParts =
      sparePartsMap[subcategory] ?? sparePartsMap['Other']!;

  return [
    {
      'label': 'Selling Type',
      'type': 'dropdown',
      'options': ['Whole Device', 'Spare/Part'],
      'default': 'Whole Device',
    },
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
    {
      'label': 'Device Type',
      'type': 'dropdown',
      'options': [
        'Smartphone',
        'Tablet',
        'Smartwatch',
        'Earbuds',
        'Accessories',
        'Feature Phone',
        'Other',
      ]
    },
    {'label': 'Brand', 'type': 'text'},
    {'label': 'Model', 'type': 'text'},
    {'label': 'Year of Purchase', 'type': 'year'},
    {
      'label': 'Condition',
      'type': 'dropdown',
      'options': ['Excellent', 'Good', 'Fair', 'Needs Repair']
    },
    {
      'label': 'Warranty Available',
      'type': 'dropdown',
      'options': ['Yes', 'No']
    },
    {'label': 'Description', 'type': 'description'},
  ];
}
