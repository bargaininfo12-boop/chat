import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/productadd/add_product/data_holder.dart';
import 'package:bargain/productadd/forms/dynamic_details_wrapper.dart';
import 'package:bargain/productadd/Config_files/vehicle_form_config.dart';
import 'package:flutter/material.dart';

class VehicleContent extends StatelessWidget {
  const VehicleContent({super.key});

  @override
  Widget build(BuildContext context) {
    final systemTheme = Theme.of(context);

    return Theme(
      data: systemTheme.brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          final String selectedCategory =
              ModalRoute.of(context)?.settings.arguments as String? ?? 'Vehicles';

          final List<Map<String, dynamic>> subCategories = [
            {'name': 'Car', 'icon': Icons.directions_car},
            {'name': 'Bike', 'icon': Icons.two_wheeler},
            {'name': 'Scooter', 'icon': Icons.electric_scooter},
            {'name': 'Truck', 'icon': Icons.local_shipping},
            {'name': 'Bus', 'icon': Icons.directions_bus},
            {'name': 'Auto Accessories', 'icon': Icons.settings},
            {'name': 'Spare Parts', 'icon': Icons.build},
            {'name': 'Other', 'icon': Icons.miscellaneous_services},
          ];

          return Scaffold(
            appBar: SectionAppBar(
              title: selectedCategory,
              onBack: () => Navigator.pop(context),
            ),
            body: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              padding: const EdgeInsets.all(16.0),
              children: subCategories.map((subcategory) {
                return _buildCard(
                  context,
                  subcategory['name'] as String,
                  selectedCategory,
                  subcategory['icon'] as IconData,
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
      BuildContext context,
      String subcategory,
      String? category,
      IconData icon,
      ) {
    final theme = Theme.of(context);
    final Color cardColor = theme.colorScheme.primaryContainer;
    final Color textColor = theme.colorScheme.onPrimaryContainer;

    return InkWell(
      onTap: () async {
        await DataHolder.startNewProduct(); // ✅ productId generated here

        DataHolder.category = category ?? '';
        DataHolder.subcategory = subcategory;

        // 🧠 Pass subcategory-specific form config dynamically
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicDetailsWrapper(
              categoryName: subcategory,
              formConfig: getVehicleFormConfig(subcategory),
            ),
          ),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        clipBehavior: Clip.antiAlias,
        color: cardColor,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: textColor),
              const SizedBox(height: 10),
              Text(
                subcategory,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
