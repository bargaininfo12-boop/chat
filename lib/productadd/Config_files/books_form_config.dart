// File: books_form_config.dart
// Version: 2.0.0
// Dynamic config for Books category
// Supports subcategories (School, Novels, Comics, etc.)
// and Selling Type (Whole Set / Single Volume)

List<Map<String, dynamic>> getBooksFormConfig(String subcategory) {
  // 🧠 Define subcategory-specific fields
  final Map<String, List<Map<String, dynamic>>> subFieldsMap = {
    'School Books': [
      {
        'label': 'Class / Grade',
        'type': 'dropdown',
        'options': ['Nursery', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th'],
      },
      {
        'label': 'Board',
        'type': 'dropdown',
        'options': ['CBSE', 'ICSE', 'State Board', 'IB', 'Other'],
      },
      {'label': 'Subject', 'type': 'text'},
    ],
    'College Books': [
      {'label': 'Stream', 'type': 'dropdown', 'options': ['Science', 'Commerce', 'Arts', 'Engineering', 'Medical', 'Other']},
      {'label': 'Semester', 'type': 'text'},
      {'label': 'Subject', 'type': 'text'},
    ],
    'Comics': [
      {'label': 'Series Name', 'type': 'text'},
      {'label': 'Volume Number', 'type': 'text'},
    ],
    'Magazines': [
      {'label': 'Month / Issue', 'type': 'text'},
      {'label': 'Category', 'type': 'dropdown', 'options': ['Fashion', 'Technology', 'Business', 'Lifestyle', 'Other']},
    ],
    'Novels': [
      {'label': 'Genre', 'type': 'dropdown', 'options': ['Fiction', 'Romance', 'Thriller', 'Fantasy', 'Biography', 'Other']},
    ],
    'Other': [
      {'label': 'Book Type', 'type': 'text'},
    ],
  };

  final List<Map<String, dynamic>> subFields =
      subFieldsMap[subcategory] ?? subFieldsMap['Other']!;

  return [
    // 🧱 Selling Type
    {
      'label': 'Selling Type',
      'type': 'dropdown',
      'options': ['Whole Set', 'Single Book'],
      'default': 'Whole Set',
    },

    // 🧩 Part-specific fields
    {
      'label': 'Part Name / Volume',
      'type': 'text',
      'dependsOn': {'label': 'Selling Type', 'value': 'Single Book'},
    },
    {
      'label': 'Part Condition',
      'type': 'dropdown',
      'options': ['New', 'Used - Good', 'Used - Damaged'],
      'dependsOn': {'label': 'Selling Type', 'value': 'Single Book'},
    },

    // 📚 Base fields
    {'label': 'Book Title', 'type': 'text'},
    {'label': 'Author', 'type': 'text'},
    {'label': 'Publisher', 'type': 'text'},

    // 🔄 Dynamic Subcategory Fields
    ...subFields,

    // 🏷️ Common fields
    {'label': 'Edition', 'type': 'text'},
    {'label': 'ISBN', 'type': 'text'},
    {
      'label': 'Condition',
      'type': 'dropdown',
      'options': ['New', 'Used'],
    },
    {'label': 'Description', 'type': 'description'},
  ];
}
