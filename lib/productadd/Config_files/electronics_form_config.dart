// File: electronics_form_config.dart

List<Map<String, dynamic>> getElectronicsFormConfig(String subcategory) {
  // 🧠 Spare part lists by subcategory
  final Map<String, List<String>> sparePartsMap = {
    'TV': ['PCB Board', 'Display Panel', 'Remote', 'Speaker Board', 'Other'],
    'AC': ['PCB Board', 'Compressor', 'Condenser Coil', 'Fan Motor', 'Other'],
    'Refrigerator': ['PCB Board', 'Door Gasket', 'Thermostat', 'Compressor', 'Other'],
    'Washing Machine': ['PCB Board', 'Motor', 'Drum', 'Belt', 'Other'],
    'Camera': ['Lens', 'Battery', 'Sensor', 'Viewfinder', 'Other'],
    'Laptop': ['Motherboard', 'RAM', 'Battery', 'Keyboard', 'Other'],
    'Mobile': ['Display', 'Battery', 'Motherboard', 'Camera Module', 'Other'],
    'Other': ['PCB', 'Generic Part', 'Accessory', 'Other'],
  };

  final List<String> spareParts =
      sparePartsMap[subcategory] ?? sparePartsMap['Other']!;

  return [
    {
      'label': 'Selling Type',
      'type': 'dropdown',
      'options': ['Whole Device', 'Spare/Part'],
      // ✅ default will be "Whole Device"
      'default': 'Whole Device',
    },

    // 🔩 Only visible when Selling Type == Spare/Part
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

    // Normal device fields
    {
      'label': 'Device Type',
      'type': 'dropdown',
      'options': [
        'Laptop',
        'Mobile',
        'Refrigerator',
        'Washing Machine',
        'TV',
        'AC',
        'Camera',
        'Other'
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
