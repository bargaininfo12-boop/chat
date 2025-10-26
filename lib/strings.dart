// strings.dart

// Subcategory-wise fields
const Map<String, List<String>> subcategories = {
  'AC': ['Brand', 'Model','Type', 'Capacity', 'Energy Rating', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Camera': ['Brand', 'Model','Type', 'Megapixels', 'Lens Included', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'TV': ['Brand', 'Model','Screen Size', 'Type', 'Resolution', 'Smart TV', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Audio': ['Brand', 'Model','Type','Noise Cancellation', 'Wireless', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Computer': ['Brand', 'Model', 'Processor', 'RAM', 'Storage', 'Graphics Card', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Laptop': ['Brand', 'Model', 'Screen Size', 'Processor', 'RAM','Storage Type', 'Storage', 'Battery Health', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Smartphone': ['Brand', 'Model', 'Storage', 'RAM', 'Condition', 'Accessories Included', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Feature Phone': ['Brand', 'Model', 'Storage', 'RAM', 'Condition', 'Accessories Included', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Tablet': ['Brand', 'Model', 'Storage', 'RAM', 'Condition', 'Accessories Included', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Accessories': ['Accessory Type', 'Brand', 'Compatible Devices', 'Condition', 'Color', 'Warranty Available', 'Warranty Period'],
  'Refrigerator': ['Brand', 'Model','Type', 'Capacity', 'Energy Rating', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Washing Machine': ['Brand','Model', 'Type', 'Capacity', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Smart Home': ['Device Type', 'Brand','Model', 'Compatibility', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Smart Speaker': ['Device Type', 'Brand','Model', 'Compatibility', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Smartwatch': ['Device Type', 'Brand','Model', 'Compatibility', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Earbuds': ['Device Type','Type', 'Brand','Model', 'Compatibility', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Gaming': ['Console Type', 'Model', 'Storage', 'Condition', 'Games Included', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Other': ['Product Name', 'Model','Brand', 'Condition', 'Description', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Power Bank': ['Device Type', 'Brand','Model', 'Capacity','Battery Type','Fast Charging','Output Ports','Input Ports' ,'Compatibility','Weight','Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Portable Router': ['Device Type', 'Brand','Connectivity', 'Speed', 'Battery Backup','SIM Support','Ports','Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Memory Card': ['Device Type', 'Brand', 'Storage Capacity', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Screen Protector': ['Device Type', 'Features','Edge Protection','Installation Type', 'Pack Size','Compatibility', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Phone Case': ['Device Type','Brand','Material','Case Type', 'Features','Design','Compatibility', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Sofa and Tables': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Beds': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Garden': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Chairs': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Wardrobes': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Desks': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Dining Tables': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Bookshelves': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Outdoor Furniture': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Office Furniture': ['Brand', 'Material', 'Dimensions', 'Capacity', 'Color', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
  'Novel': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Language', 'ISBN', 'Condition'],
  'Science Book': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Subject', 'ISBN', 'Condition'],
  'Fiction Book': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Genre', 'ISBN', 'Condition'],
  'Non-Fiction Book': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Category', 'ISBN', 'Condition'],
  'Literature Book': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Language', 'ISBN', 'Condition'],
  'Storybooks': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Language', 'ISBN', 'Condition'],
  'School Book': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Class/Grade', 'Subject', 'Class', 'ISBN', 'Condition'],
  'College Books': ['Book Title', 'Author', 'Publisher', 'Publication Year', 'Course', 'Class', 'ISBN', 'Condition'],
  'Selfie Stick': ['Device Type', 'Brand', 'Maximum Length' ,'Rotation','Grip Type','Remote Control', 'Battery Life','Compatibility', 'Condition', 'Bill Available', 'Warranty Available', 'Warranty'],
};

// Dropdown options for fields
const Map<String, Map<String, List<String>>> dropdownOptions = {
  'AC': {
    'Brand': [
      'Daikin', 'Voltas', 'LG', 'Samsung', 'Panasonic', 'Blue Star', 'Godrej', 'Hitachi',
      'Mitsubishi', 'Carrier', 'Whirlpool', 'O General', 'Croma', 'BPL', 'IFB', 'Micromax',
      'Midea', 'Realme', 'Sansui', 'Singer', 'TCL', 'Thomson', 'Toshiba', 'Trane',
      'Vestar', 'Videocon', 'Haier', 'Hisense', 'Livpure', 'Lloyd'
    ],
    'Type': ['Split', 'Window', 'Portable', 'Central', 'Ducted/VRF/VRV', 'Cassette'],
    'Capacity': ['0.75 Ton', '1 Ton', '1.5 Ton', '2 Ton', '3 Ton'],
    'Energy Rating': ['1 Star', '2 Star', '3 Star', '4 Star', '5 Star'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years', '3 Years', '5 Years'],
  },
  'Camera': {
    'Brand': [ 'Canon', 'Nikon', 'Sony', 'Fujifilm', 'Olympus', 'Panasonic', 'Pentax', 'Leica', 'Ricoh', 'Hasselblad', 'GoPro', 'Kodak'],
    'Type': ['DSLR', 'Mirrorless', 'Point-and-Shoot', 'Bridge', 'Action', 'Medium Format', 'Film', 'Instant', 'Rangefinder'],
    'Lens Included': ['Yes', 'No'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },
  'TV': {
    'Brand': ['Sony', 'Samsung', 'LG', 'Panasonic', 'Philips', 'Micromax','Motorola','TCL', 'Hisense', 'Vizio', 'Sharp', 'Toshiba','Other'],
    'Screen Size': ['24"', '28"', '32"', '40"', '43"', '49"', '50"', '55"', '60"', '65"', '70"', '75"', '82"', '85"'] ,
    'Type': ['CRT','LED', 'OLED', 'QLED', 'LCD', 'Plasma', 'Mini-LED', 'MicroLED'],
    'Resolution': ['HD', 'Full HD', 'Quad HD', '4K', '8K'],
    'Smart TV': ['Yes', 'No'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['1 Year', '2 Years', '3 Years'],
  },
  'Audio': {
    'Brand': [
      'Amazon Basics', 'Apple', 'Audio-Technica', 'AKG', 'Beats by Dre', 'boAt', 'Bose', 'HP', 'JBL', 'LG', 'Mivi', 'Noise', 'OnePlus', 'Panasonic', 'Philips', 'Portronics', 'pTron', 'Realme', 'Redmi', 'Saregama', 'Sennheiser', 'Skullcandy', 'Sony', 'Zebronics', 'Marshall'],
      'Type': ['Speakers', 'Soundbars', 'Portable Speakers', 'True Wireless Earbuds', 'Smart Speakers', 'Home Theater Systems', 'Car Audio Systems', 'PA Systems'],
    'Wireless': ['Yes', 'No'],
    'Noise Cancellation' : ['Yes','No'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },
  'Computer': {
    'Brand': ['Dell', 'HP', 'Lenovo', 'Apple', 'Asus', 'Acer', 'Microsoft', 'MSI', 'Razer', 'Samsung', 'Toshiba', 'Sony', 'Huawei', 'LG', 'Gigabyte', 'Alienware', 'Vaio', 'Xiaomi', 'Chuwi', 'Jumper', 'Avita', 'Realme', 'iBall', 'Lava', 'Infinix', 'Panasonic', 'Fujitsu', 'NEC', 'Google', 'Clevo'
    ],
    'Screen Size': ['11.6"', '13.3"', '14"', '15.6"', '17.3"'],
    'Processor': ['Intel Celeron', 'Intel Pentium', 'Intel Core i3', 'Intel Core i5', 'Intel Core i7', 'Intel Core i9', 'AMD Athlon', 'AMD Ryzen 3', 'AMD Ryzen 5', 'AMD Ryzen 7', 'AMD Ryzen 9', 'Apple M1', 'Apple M2'],
    'RAM': ['4GB', '8GB', '16GB', '32GB', '64GB'],
    'Storage Type': ['SSD','HDD'],
    'Storage': ['256GB SSD', '512GB SSD', '1TB SSD', '1TB HDD', '2TB HDD', '512GB SSD + 1TB HDD'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['1 Year', '2 Years', '3 Years'],
  },
  'Laptop': {
    'Brand': ['Dell', 'HP', 'Lenovo', 'Apple', 'Asus', 'Acer', 'Microsoft', 'MSI', 'Razer', 'Samsung', 'Toshiba', 'Sony', 'Huawei', 'LG', 'Gigabyte', 'Alienware', 'Vaio', 'Xiaomi', 'Chuwi', 'Jumper', 'Avita', 'Realme', 'iBall', 'Lava', 'Infinix', 'Panasonic', 'Fujitsu', 'NEC', 'Google', 'Clevo'
    ],
    'Screen Size': ['11.6"', '13.3"', '14"', '15.6"', '17.3"'],
    'Processor': ['Intel Celeron', 'Intel Pentium', 'Intel Core i3', 'Intel Core i5', 'Intel Core i7', 'Intel Core i9', 'AMD Athlon', 'AMD Ryzen 3', 'AMD Ryzen 5', 'AMD Ryzen 7', 'AMD Ryzen 9', 'Apple M1', 'Apple M2'],
    'RAM': ['4GB', '8GB', '16GB', '32GB', '64GB'],
    'Storage Type': ['SSD','HDD'],
    'Storage': ['256GB SSD', '512GB SSD', '1TB SSD', '1TB HDD', '2TB HDD', '512GB SSD + 1TB HDD'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['1 Year', '2 Years', '3 Years'],
  },

  'Beds': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },


  'Garden': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },


  'Chairs': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },


  'Wardrobes': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },

  'Desks': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },

  'Dining Tables': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },

  'Bookshelves': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },

  'Outdoor Furniture': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },

  'Office Furniture': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },

  'Sofa and Tables': {
    'Brand': ['IKEA', 'Home Centre', 'Ashley', 'Local Brand', 'Other'],
    'Material': ['Wood', 'Metal', 'Glass', 'Composite', 'Plastic'],
    'Dimensions': ['Custom Entry'], // Dimensions ko user input ya custom entry ke roop mein handle kar sakte hain
    'Capacity': ['Small', 'Medium', 'Large'],
    'Color': ['White', 'Black', 'Brown', 'Grey', 'Blue', 'Other'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },
  'Smartphone': {
    'Brand': ['Samsung', 'Apple', 'Xiaomi', 'OnePlus'],
    'Storage': ['64GB', '128GB', '256GB','Upto 256GB'],
    'RAM': ['4GB', '6GB', '8GB','16GB','32GB','Upto 32GB'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Accessories Included': ['Charger', 'Earphones','Charger & Earphone', 'No'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },
  'Earbuds': {
    'Brand': ['Amazon Basics', 'Apple', 'Audio-Technica', 'AKG', 'Beats by Dre', 'boAt', 'Bose', 'HP', 'JBL', 'LG', 'Mivi', 'Noise', 'OnePlus', 'Panasonic', 'Philips', 'Portronics', 'pTron', 'Realme', 'Redmi', 'Saregama', 'Sennheiser', 'Skullcandy', 'Sony', 'Zebronics', 'Marshall'],
    'Type': ['Earbuds', 'Earphone','OverEars','Other'],
    'Compatibility': ['iOS', 'Android', 'Windows'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Color': ['Black', 'White', 'Blue', 'Red', 'Green'],
    'Battery Life': ['Up to 10 hours', 'Up to 20 hours', 'Up to 30 hours','Up to 70 hours','Up to 100 hours'],
    'Noise Cancellation': ['Yes', 'No'],
    'Water Resistance': ['IPX4', 'IPX5', 'IPX7', 'No'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years']
  },

  'Smart Speaker': {
    'Device Type': ['Smart Speaker'],
    'Brand': ['Amazon', 'Google', 'Apple', 'Sony', 'Bose', 'JBL'],
    'Model': ['Echo Dot', 'Nest Audio', 'HomePod', 'SoundLink', 'Flip 6','Other'],
    'Compatibility': ['Alexa', 'Google Assistant', 'Siri'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years']
  },

  'Smartwatch': {
    'Brand': ['Apple', 'Samsung', 'Garmin', 'Fitbit', 'Amazfit', 'Boat', 'Noise', 'OnePlus','Other'],
    'Compatibility': ['iOS', 'Android', 'Both'],
    'Display Type': ['AMOLED', 'LCD', 'OLED'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Strap Material': ['Silicone', 'Leather', 'Metal','other'],
    'Battery Life': ['Up to 2 days', 'Up to 7 days', 'Up to 14 days','Up to 60 Days '],
    'Water Resistance': ['IP67', 'IP68', '5ATM', 'No'],
    'Features': ['Heart Rate Monitor', 'SpO2 Sensor', 'GPS', 'ECG', 'Bluetooth Calling'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years']
  },

  'Feature Phone': {
    'Device Type': ['Feature Phone', 'Basic Phone', 'Keypad Phone'],
    'Brand': ['Nokia', 'Samsung', 'Itel', 'Lava', 'Micromax', 'Jio', 'Karbonn'],
    'Model': ['Nokia 105', 'Samsung Guru Music 2', 'JioPhone 2', 'Lava A7'],
    'Network': ['2G', '3G', '4G VoLTE'],
    'SIM Type': ['Single SIM', 'Dual SIM'],
    'Battery Capacity': ['800mAh', '1000mAh', '1200mAh', '1500mAh', '2000mAh'],
    'Display Size': ['1.8 inch', '2.4 inch', '2.8 inch'],
    'Camera': ['No Camera', 'VGA', '2MP'],
    'Storage': ['Up to 32MB', 'Up to 512MB', 'Expandable via microSD'],
    'Connectivity': ['Bluetooth', 'FM Radio', '3.5mm Jack', 'Micro-USB'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Torch Light': ['Yes', 'No'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years']
  },


  'Power Bank': {
    'Device Type': ['Power Bank'],
    'Brand': ['MI', 'Realme', 'Samsung', 'Ambrane', 'Syska', 'Anker', 'Boat'],
    'Capacity': ['5000mAh', '10000mAh', '15000mAh', '20000mAh', '30000mAh'],
    'Battery Type': ['Lithium-ion', 'Lithium-polymer'],
    'Fast Charging': ['Yes', 'No'],
    'Output Ports': ['Single USB', 'Dual USB', 'Type-C & USB'],
    'Input Ports': ['Micro-USB', 'Type-C'],
    'Compatibility': ['Smartphones', 'Tablets', 'Smartwatches', 'Laptops'],
    'Weight': ['Lightweight', 'Medium', 'Heavy'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years']
  },


  'Phone Case': {
    'Device Type': ['Smartphone Case', 'Tablet Case'],
    'Brand': ['Spigen', 'Ringke', 'OtterBox', 'UAG', 'Caseology', 'ESR', 'Supcase'],
    'Material': ['Silicone', 'TPU', 'Polycarbonate', 'Leather', 'Hybrid', 'Metal', 'Fabric'],
    'Case Type': ['Back Cover', 'Flip Cover', 'Bumper Case', 'Wallet Case', 'Armored Case', 'Transparent Case', 'Kickstand Case'],
    'Features': ['Shockproof', 'Waterproof', 'Anti-Fingerprint', 'MagSafe Compatible', 'Wireless Charging Support', '360° Protection'],
    'Compatibility': ['iPhone', 'Samsung Galaxy', 'OnePlus', 'Xiaomi', 'Google Pixel', 'Motorola'],
    'Design': ['Plain', 'Printed', 'Customizable', 'Textured', 'Rugged'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year']
  },


  'Selfie Stick': {
    'Device Type': ['Wired Selfie Stick', 'Wireless Bluetooth Selfie Stick', 'Tripod Selfie Stick', 'Gimbal Selfie Stick'],
    'Brand': ['MI', 'Realme', 'Samsung', 'Sony', 'DJI', 'Spigen', 'boAt'],
    'Material': ['Aluminum', 'Stainless Steel', 'Plastic'],
    'Compatibility': ['Smartphones', 'Action Cameras', 'DSLR Cameras'],
    'Maximum Length': ['Up to 50cm', 'Up to 100cm', 'Up to 150cm'],
    'Rotation': ['180°', '360°'],
    'Grip Type': ['Rubberized', 'Foam', 'Plastic'],
    'Remote Control': ['Yes', 'No'],
    'Battery Life (for Bluetooth models)': ['Up to 5 hours', 'Up to 10 hours','No Battery'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years']
  },


  'Portable Router': {
    'Device Type': ['Portable Router', 'Mobile Hotspot'],
    'Brand': ['TP-Link', 'Netgear', 'Huawei', 'JioFi', 'D-Link', 'ZTE'],
    'Connectivity': ['4G LTE', '5G', 'Wi-Fi 6', 'Dual-Band Wi-Fi'],
    'Speed': ['Up to 150 Mbps', 'Up to 300 Mbps', 'Up to 1 Gbps'],
    'Battery Backup': ['4 Hours', '6 Hours', '10 Hours', '24 Hours'],
    'SIM Support': ['Yes', 'No'],
    'Ports': ['USB-C', 'Micro-USB', 'Ethernet'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years']
  },



  'Tablet': {
    'Brand': ['Samsung', 'Apple', 'Xiaomi', 'OnePlus'],
    'Storage': ['64GB', '128GB', '256GB','Upto 256GB'],
    'RAM': ['4GB', '6GB', '8GB','16GB','32GB','Upto 32GB'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Accessories Included': ['Charger', 'Earphones','Charger & Earphone', 'No'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },

  'Accessories': {
    'Accessory Type': ['Charger', 'Cable', 'Adapter', 'Holder', 'Screen Protector'],
    'Brand': ['Samsung', 'Apple', 'Xiaomi', 'OnePlus', 'Boat', 'Sony','other'],
    'Compatible Devices': ['Mobile', 'Tablet', 'Laptop', 'Smartwatch'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Color': ['Black', 'White', 'Red', 'Blue', 'Green'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty Period': ['3 Months', '6 Months', '1 Year', '2 Years']
  },

  'Refrigerator': {
    'Brand': ['LG', 'Samsung', 'Whirlpool', 'Godrej', 'Haier', 'Panasonic', 'Voltas', 'Bosch', 'Blue Star'],
    'Type': ['Single Door', 'Double Door','Triple Door', 'Side-by-Side', 'Mini','Table Top'],
    'Energy Rating': ['1 Star', '2 Star', '3 Star', '4 Star', '5 Star'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['1 Year', '2 Years', '5 Years'],
  },

  'Memory Card': {
    'Device Type': ['MicroSD Card', 'SD Card', 'CF Card'],
    'Brand': ['SanDisk', 'Samsung', 'Kingston', 'Sony', 'Lexar', 'Strontium', 'Transcend'],
    'Storage Capacity': ['16GB', '32GB', '64GB', '128GB', '256GB', '512GB', '1TB'],
    'Condition': ['New', 'Used', 'Refurbished'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '5 Years', 'Lifetime Warranty']
  },

  'Screen Protector': {
    'Device Type': ['Smartphone Screen Protector', 'Tablet Screen Protector', 'Laptop Screen Protector', 'Smartwatch Screen Protector'],
    'Features': ['Anti-Glare', 'Anti-Fingerprint', 'Privacy Screen', 'Matte Finish', 'Blue Light Filter'],
    'Compatibility': ['iPhone', 'Samsung Galaxy', 'OnePlus', 'Xiaomi', 'iPad', 'MacBook', 'Smartwatch Models'],
    'Installation Type': ['Easy Install Frame', 'Wet Install', 'Dry Install'],
    'Edge Protection': ['2.5D Rounded Edges', '3D Full Cover', 'Edge-to-Edge'],
    'Pack Size': ['Single Pack', '2-Pack', '3-Pack', '5-Pack','10-Pack','20-pack','30-pack','40-pack'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year']
  },



  'Washing Machine': {
    'Brand': ['LG', 'Samsung', 'Whirlpool', 'IFB', 'Haier', 'Panasonic', 'Godrej', 'Onida', 'Bosch', 'Lloyd'],
    'Type': ['Semi-Automatic','Fully Automatic'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['1 Year', '2 Years', '5 Years'],
  },
  'Smart Home': {
    'Device Type': ['Smart Speakers & Voice Assistants', 'Smart Lighting', 'Smart Security & Surveillance', 'Smart Thermostats', 'Smart Appliances', 'Smart Entertainment Devices', 'Smart Sensors', 'Smart Plugs & Outlets', 'Smart Home Hubs & Controllers', 'Smart Curtains & Blinds', 'Smart Irrigation & Garden Systems'],
    'Brand': ['Philips', 'Amazon', 'Google', 'Samsung', 'Xiaomi', 'Honeywell', 'Ecobee', 'Belkin', 'Lutron', 'Ring', 'Arlo', 'August', 'TP-Link', 'Bosch', 'IKEA', 'GE', 'iRobot', 'Ecovacs', 'Neato Robotics', 'Sonos'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },
  'Gaming': {
    'Brand': ['Razer', 'Logitech', 'Corsair', 'SteelSeries', 'HyperX', 'ASUS ROG', 'Acer Predator', 'MSI Gaming', 'Dell Alienware', 'HP Omen', 'Lenovo Legion', 'Gigabyte Aorus', 'NZXT', 'Cooler Master', 'Redragon', 'Microsoft Xbox', 'Sony PlayStation', 'Nintendo', 'Roccat', 'EVGA'],
    'Type': ['Game Full With All Accessories', 'Only Console'],
    'Storage': ['256GB', '500GB', '512GB', '1TB', '2TB','No Storage'],
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['1 Year', '2 Years'],
  },
  'Other': {
    'Condition': ['New', 'Used'],
    'Bill Available': ['Yes', 'No'],
    'Warranty Available': ['Yes', 'No'],
    'Warranty': ['6 Months', '1 Year', '2 Years'],
  },
};

class Strings {
  // AppBar Title
  static String vehicleDetailsTitle(String? vehicleType) => '$vehicleType Details';

  // Button Text
  static const String nextButton = 'Next';
  static const String submitButton = 'Submit'; // Added for clarity in Stepper

  // Common Field Labels
  static const String productTitleLabel = 'Product Title';
  static const String vehicleTypeLabel = 'Vehicle Type';
  static const String brandLabel = 'Brand';
  static const String modelLabel = 'Model';
  static const String descriptionLabel = 'Description';

  // Validation Error
  static const String requiredFieldError = 'This field is required';

  // Vehicle Common Field Labels
  static const String yearLabel = 'Year';
  static const String kmDrivenLabel = 'KM Driven';
  static const String ownershipLabel = 'Ownership';
  static const String fuelTypeLabel = 'Fuel Type';
  static const String registrationNumberLabel = 'Registration Number';

  // Bike-Specific Labels
  static const String engineDisplacementLabel = 'Engine Displacement';
  static const String bikeTypeLabel = 'Bike Type';
  static const String topSpeedLabel = 'Top Speed';
  static const String fuelTankCapacityLabel = 'Fuel Tank Capacity';
  static const String seatHeightLabel = 'Seat Height';

  // Car-Specific Labels
  static const String engineSizeLabel = 'Engine Size';
  static const String numberOfDoorsLabel = 'Number of Doors';
  static const String seatingCapacityLabel = 'Seating Capacity';
  static const String CarType = 'Car Type';


  // Trucks & Commercial Vehicles Labels
  static const String towingCapacityLabel = 'Towing Capacity';
  static const String numberOfAxlesLabel = 'Number of Axles';

  // Spare Part Labels
  static const String sparePartCategoryLabel = 'Vehicle Category';
  static const String partTypeLabel = 'Part Type';
  static const String compatibleVehiclesLabel = 'Compatible Vehicles';
  static const String partConditionLabel = 'Part Condition';
  static const String warrantyLabel = 'Warranty';
  static const String materialLabel = 'Material';

  // Other Labels
  static const String purposeLabel = 'Purpose';
  static const String weightLabel = 'Weight';
  static const String dimensionsLabel = 'Dimensions';

  // Electric Vehicles Labels
  static const String batteryCapacityLabel = 'Battery Capacity';
  static const String rangeLabel = 'Range';
  static const String chargingTimeLabel = 'Charging Time';
  static const String chargingConnectorTypeLabel = 'Charging Connector Type';
  static const String fastChargingLabel = 'Fast Charging';

  // Hybrid Vehicles Labels
  static const String electricRangeLabel = 'Electric Range';
  static const String fuelEfficiencyLabel = 'Fuel Efficiency';
  static const String chargingOptionLabel = 'Charging Option';


  // Off-road Vehicles Labels
  static const String groundClearanceLabel = 'Ground Clearance';
  static const String tireTypeLabel = 'Tire Type';
  static const String fourWheelDriveLabel = '4WD';
  static const String anglesLabel = 'Approach/Departure Angles';

  // Auto Accessories Labels
  static const String accessoryTypeLabel = 'Accessory Type';

  // Heavy Machinery Labels
  static const String operatingWeightLabel = 'Operating Weight';
  static const String enginePowerLabel = 'Engine Power';
  static const String hoursUsedLabel = 'Hours Used';

  // Dropdown Options
  static const List<String> allBrands = [
    'Maruti Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Honda', 'Toyota', 'Ford',
    'Renault', 'Volkswagen', 'Skoda', 'Audi', 'BMW', 'Mercedes-Benz', 'Nissan',
    'Kia', 'MG', 'Jeep', 'Hero', 'Bajaj', 'TVS', 'Royal Enfield', 'KTM', 'Yamaha',
    'Suzuki', 'Ashok Leyland', 'Other'
  ];
  static const List<String> carBrands = [
    'Maruti Suzuki', 'Hyundai', 'Tata', 'Mahindra', 'Honda', 'Toyota', 'Ford',
    'Renault', 'Volkswagen', 'Skoda', 'Audi', 'BMW', 'Mercedes-Benz', 'Nissan',
    'Kia', 'MG', 'Jeep', 'Other'
  ];

  static const List<String> Cartype = [
    'Electric Car', 'off-Road Car','4*4 Car','Hybrid Car'
  ];

  static const List<String> bikeBrands = [
    'Hero', 'Bajaj', 'TVS', 'Royal Enfield', 'KTM', 'Yamaha', 'Honda', 'Suzuki', 'Other'
  ];
  static const List<String> truckBrands = [
    'Tata', 'Ashok Leyland', 'Eicher', 'BharatBenz', 'Mahindra', 'Other'
  ];
  static const List<String> ownerships = ['First', 'Second', 'Third', 'Other'];
  static const List<String> fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric', 'Other'];
  static const List<String> bikeTypes = ['Sports', 'Cruiser', 'Scooter', 'Other'];
  static const List<String> safetyFeaturesOptions = ['Airbags', 'ABS', 'Lane Assist'];
  static const List<String> luxuryFeaturesOptions = ['Leather Seats', 'Premium Sound', 'Sunroof'];
  static const List<String> attachmentsOptions = ['Bucket', 'Blade', 'Fork'];
  static const List<String> sparePartCategories = ['Car', 'Bike', 'Truck'];

  // Map Keys for additionalDetails
  static const String productTitleKey = 'Product Title';
  static const String vehicleTypeKey = 'Vehicle Type';
  static const String brandKey = 'Brand';
  static const String modelKey = 'Model';
  static const String descriptionKey = 'Description';
  static const String yearKey = 'Year';
  static const String kmDrivenKey = 'KM Driven';
  static const String ownershipKey = 'Ownership';
  static const String fuelTypeKey = 'Fuel Type';
  static const String registrationNumberKey = 'Registration Number';
  static const String engineDisplacementKey = 'Engine Displacement';
  static const String bikeTypeKey = 'Bike Type';
  static const String topSpeedKey = 'Top Speed';
  static const String fuelTankCapacityKey = 'Fuel Tank Capacity';
  static const String seatHeightKey = 'Seat Height';
  static const String engineSizeKey = 'Engine Size';
  static const String numberOfDoorsKey = 'Number of Doors';
  static const String seatingCapacityKey = 'Seating Capacity';
  static const String safetyFeaturesKey = 'Safety Features';
  static const String towingCapacityKey = 'Towing Capacity';
  static const String numberOfAxlesKey = 'Number of Axles';
  static const String sparePartCategoryKey = 'Spare Part Category';
  static const String partTypeKey = 'Part Type';
  static const String compatibleVehiclesKey = 'Compatible Vehicles';
  static const String partConditionKey = 'Condition';
  static const String warrantyKey = 'Warranty';
  static const String materialKey = 'Material';
  static const String batteryCapacityKey = 'Battery Capacity';
  static const String rangeKey = 'Range';
  static const String chargingTimeKey = 'Charging Time';
  static const String chargingConnectorTypeKey = 'Charging Connector Type';
  static const String fastChargingKey = 'Fast Charging';
  static const String electricRangeKey = 'Electric Range';
  static const String fuelEfficiencyKey = 'Fuel Efficiency';
  static const String chargingOptionKey = 'Charging Option';
  static const String luxuryFeaturesKey = 'Luxury Features';
  static const String warrantyInfoKey = 'Warranty Info';
  static const String groundClearanceKey = 'Ground Clearance';
  static const String tireTypeKey = 'Tire Type';
  static const String fourWheelDriveKey = '4WD';
  static const String anglesKey = 'Angles';
  static const String accessoryTypeKey = 'Accessory Type';
  static const String operatingWeightKey = 'Operating Weight';
  static const String enginePowerKey = 'Engine Power';
  static const String hoursUsedKey = 'Hours Used';
  static const String attachmentsKey = 'Attachments';
  static const String dimensionsKey = 'Dimensions';

  // Subcategories और उनके फील्ड्स (DetailsScreen के लिए)
  static const Map<String, List<String>> subcategories = {
    'Bike': [
      brandLabel,
      modelLabel,
      yearLabel,
      kmDrivenLabel,
      ownershipLabel,
      fuelTypeLabel,
      registrationNumberLabel,
      engineDisplacementLabel,
      bikeTypeLabel,
      topSpeedLabel,
      fuelTankCapacityLabel,
      seatHeightLabel,
    ],
    'Car': [
      CarType,
      brandLabel,
      modelLabel,
      yearLabel,
      kmDrivenLabel,
      ownershipLabel,
      fuelTypeLabel,
      registrationNumberLabel,
      engineSizeLabel,
      numberOfDoorsLabel,
      seatingCapacityLabel,
    ],
    'Trucks': [
      brandLabel,
      modelLabel,
      yearLabel,
      kmDrivenLabel,
      ownershipLabel,
      fuelTypeLabel,
      registrationNumberLabel,
      towingCapacityLabel,
      numberOfAxlesLabel,
    ],
    'Spare Part': [
      productTitleLabel,
      sparePartCategoryLabel,
      partTypeLabel,
      compatibleVehiclesLabel,
      materialLabel,
      partConditionLabel,
      warrantyLabel,
    ],
    'Electric Vehicles': [
      brandLabel,
      modelLabel,
      yearLabel,
      kmDrivenLabel,
      ownershipLabel,
      registrationNumberLabel,
      batteryCapacityLabel,
      rangeLabel,
      chargingTimeLabel,
      chargingConnectorTypeLabel,
      fastChargingLabel,
    ],
    'Hybrid Vehicles': [
      brandLabel,
      modelLabel,
      yearLabel,
      kmDrivenLabel,
      ownershipLabel,
      fuelTypeLabel,
      registrationNumberLabel,
      batteryCapacityLabel,
      electricRangeLabel,
      fuelEfficiencyLabel,
      chargingOptionLabel,
    ],
    'Luxury Cars': [
      brandLabel,
      modelLabel,
      yearLabel,
      kmDrivenLabel,
      ownershipLabel,
      fuelTypeLabel,
      registrationNumberLabel,
    ],
    'Commercial Vehicles': [
      brandLabel,
      modelLabel,
      yearLabel,
      kmDrivenLabel,
      ownershipLabel,
      fuelTypeLabel,
      registrationNumberLabel,
      towingCapacityLabel,
      numberOfAxlesLabel,
    ],

    'Auto Accessories': [
      accessoryTypeLabel,
      compatibleVehiclesLabel,
      materialLabel,
      partConditionLabel,
    ],
    'Heavy Machinery': [
      brandLabel,
      modelLabel,
      yearLabel,
      operatingWeightLabel,
      enginePowerLabel,
      hoursUsedLabel,
    ],
    'Other': [
      productTitleLabel,
      descriptionLabel,
      weightLabel,
      dimensionsLabel,
    ],
  };

  // Dropdown Options for Subcategories (DetailsScreen के लिए)
  static const Map<String, Map<String, List<String>>> dropdownOptions = {
    'Bike': {
      brandLabel: bikeBrands,
      ownershipLabel: ownerships,
      fuelTypeLabel: fuelTypes,
      bikeTypeLabel: bikeTypes,
    },
    'Car': {
      CarType: Cartype,
      brandLabel: carBrands,
      ownershipLabel: ownerships,
      fuelTypeLabel: fuelTypes,
    },
    'Trucks': {
      brandLabel: truckBrands,
      ownershipLabel: ownerships,
      fuelTypeLabel: fuelTypes,
    },
    'Spare Part': {
      sparePartCategoryLabel: sparePartCategories,
      partConditionLabel: ['New', 'Used', 'Refurbished'],
    },
    'Electric Vehicles': {
      brandLabel: allBrands,
      ownershipLabel: ownerships,
    },
    'Hybrid Vehicles': {
      brandLabel: carBrands,
      ownershipLabel: ownerships,
      fuelTypeLabel: fuelTypes,
    },
    'Luxury Cars': {
      brandLabel: carBrands,
      ownershipLabel: ownerships,
      fuelTypeLabel: fuelTypes,
    },
    'Commercial Vehicles': {
      brandLabel: truckBrands,
      ownershipLabel: ownerships,
      fuelTypeLabel: fuelTypes,
    },
    'Off-road Vehicles': {
      brandLabel: allBrands,
      ownershipLabel: ownerships,
      fuelTypeLabel: fuelTypes,
    },
    'Common': {
      brandLabel: allBrands,
    },
  };
}




