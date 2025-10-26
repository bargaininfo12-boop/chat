// File: furniture_form_config.dart
// Version: 2.0.0
// Dynamic form config for Furniture category
// Adapts fields by subcategory (Bed, Sofa, Chair, etc.)

List<Map<String, dynamic>> getFurnitureFormConfig(String subcategory) {
  final Map<String, List<Map<String, dynamic>>> subFieldsMap = {
    'Sofa': [
      {
        'label': 'Seating Capacity',
        'type': 'dropdown',
        'options': ['1 Seater', '2 Seater', '3 Seater', '4+ Seater'],
      },
      {
        'label': 'Material',
        'type': 'dropdown',
        'options': ['Fabric', 'Leather', 'Wood', 'Metal', 'Other'],
      },
    ],
    'Bed': [
      {
        'label': 'Bed Size',
        'type': 'dropdown',
        'options': ['Single', 'Double', 'Queen', 'King', 'Other'],
      },
      {
        'label': 'Storage Type',
        'type': 'dropdown',
        'options': ['With Storage', 'Without Storage'],
      },
      {
        'label': 'Material',
        'type': 'dropdown',
        'options': ['Wood', 'Metal', 'Mixed'],
      },
    ],
    'Chair': [
      {
        'label': 'Chair Type',
        'type': 'dropdown',
        'options': ['Dining Chair', 'Office Chair', 'Plastic Chair', 'Folding', 'Other'],
      },
      {
        'label': 'Material',
        'type': 'dropdown',
        'options': ['Wood', 'Metal', 'Plastic', 'Leather', 'Other'],
      },
    ],
    'Table': [
      {
        'label': 'Table Type',
        'type': 'dropdown',
        'options': ['Dining', 'Coffee', 'Study', 'Side Table', 'Other'],
      },
      {
        'label': 'Shape',
        'type': 'dropdown',
        'options': ['Rectangular', 'Square', 'Round', 'Other'],
      },
    ],
    'Wardrobe': [
      {
        'label': 'No. of Doors',
        'type': 'dropdown',
        'options': ['2', '3', '4', 'More'],
      },
      {
        'label': 'Material',
        'type': 'dropdown',
        'options': ['Wood', 'Metal', 'Laminate', 'Other'],
      },
    ],
    'Other': [
      {
        'label': 'Furniture Type',
        'type': 'text',
      },
      {
        'label': 'Material',
        'type': 'dropdown',
        'options': ['Wood', 'Metal', 'Plastic', 'Glass', 'Mixed'],
      },
    ],
  };

  final List<Map<String, dynamic>> subFields =
      subFieldsMap[subcategory] ?? subFieldsMap['Other']!;

  return [
    // 🧱 Selling Type
    {
      'label': 'Selling Type',
      'type': 'dropdown',
      'options': ['Whole Item', 'Spare Part'],
      'default': 'Whole Item',
    },

    // 🧩 Spare Part fields (only visible if Spare Part selected)
    {
      'label': 'Part Name',
      'type': 'text',
      'dependsOn': {'label': 'Selling Type', 'value': 'Spare Part'},
    },
    {
      'label': 'Part Condition',
      'type': 'dropdown',
      'options': ['New', 'Used - Good', 'Used - Damaged'],
      'dependsOn': {'label': 'Selling Type', 'value': 'Spare Part'},
    },

    // 🛋 Base furniture info
    {'label': 'Brand', 'type': 'text'},
    {'label': 'Color', 'type': 'text'},
    {'label': 'Dimensions (LxWxH in cm)', 'type': 'text'},

    // 🪑 Dynamic fields based on subcategory
    ...subFields,

    {
      'label': 'Condition',
      'type': 'dropdown',
      'options': ['New', 'Used'],
    },
    {'label': 'Description', 'type': 'description'},
  ];
}
