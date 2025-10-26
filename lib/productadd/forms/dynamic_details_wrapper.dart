import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/productadd/forms/dynamic_form_screen.dart';
import 'package:bargain/productadd/price_form/price_form_screen.dart';
import 'package:bargain/productadd/price_form/location_form_screen.dart';
import 'package:bargain/productadd/add_product/data_holder.dart';
import 'package:bargain/productadd/productimageupload/image_upload.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DynamicDetailsWrapper extends StatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> formConfig;

  const DynamicDetailsWrapper({
    super.key,
    required this.categoryName,
    required this.formConfig,
  });

  @override
  State<DynamicDetailsWrapper> createState() => _DynamicDetailsWrapperState();
}

class _DynamicDetailsWrapperState extends State<DynamicDetailsWrapper> {
  int _currentTabIndex = 0;
  final PageController _pageController = PageController();

  Map<String, String> _formData = Map<String, String>.from(DataHolder.details);
  String? _selectedPrice = DataHolder.priceData;
  String? _selectedAddress = DataHolder.locationData;

  LatLng? _selectedCoordinates = (DataHolder.locationLat != null &&
      DataHolder.locationLong != null)
      ? LatLng(DataHolder.locationLat!, DataHolder.locationLong!)
      : null;

  Map<String, String>? _locationDetails = {
    "streetAddress": DataHolder.streetAddress ?? "",
    "area": DataHolder.area ?? "",
    "city": DataHolder.city ?? "",
    "state": DataHolder.state ?? "",
    "pincode": DataHolder.pincode ?? "",
  };

  void _handleNextOrSubmit() {
    if (_currentTabIndex < 2) {
      _pageController.nextPage(
        duration: AppTheme.mediumDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _validateAndSubmit();
    }
  }

  void _validateAndSubmit() {
    final missing = <String>[];

    if (_formData.isEmpty) missing.add("Details");
    if (_selectedPrice == null ||
        _selectedPrice!.isEmpty ||
        double.tryParse(_selectedPrice!) == null ||
        double.parse(_selectedPrice!) <= 0) {
      missing.add("Price");
    }
    if (_selectedAddress == null || _selectedAddress!.isEmpty) {
      missing.add("Location");
    }

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Missing fields: ${missing.join(", ")}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // ✅ Save product details (excluding description)
    DataHolder.details = Map<String, dynamic>.from(_formData);
    DataHolder.subcategoryData = widget.categoryName;
    DataHolder.isActive = true;

    // ✅ Save separate description (from DynamicFormScreen)
    DataHolder.description = DataHolder.description?.trim().isNotEmpty == true
        ? DataHolder.description
        : null;

    // ✅ Save price
    DataHolder.priceData = _selectedPrice;

    // ✅ Save location info
    DataHolder.locationData = _selectedAddress;
    if (_selectedCoordinates != null) {
      DataHolder.locationLat = _selectedCoordinates!.latitude;
      DataHolder.locationLong = _selectedCoordinates!.longitude;
    }

    if (_locationDetails != null) {
      DataHolder.streetAddress =
      _locationDetails!['streetAddress']?.isNotEmpty == true
          ? _locationDetails!['streetAddress']
          : DataHolder.area;
      DataHolder.area = _locationDetails!['area'];
      DataHolder.city = _locationDetails!['city'];
      DataHolder.state = _locationDetails!['state'];
      DataHolder.pincode = _locationDetails!['pincode'];
    }

    // ✅ Proceed to Upload (fixed screen import)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ImageUploadScreen()),
    );
  }

  Widget _buildCustomTabBar() {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(theme),
        borderRadius: AppTheme.mediumRadius,
        border: AppTheme.glassBorder(theme),
        boxShadow: AppTheme.cardShadow(theme),
      ),
      child: Row(
        children: [
          _buildTabItem(0, Icons.info, "Details"),
          _buildTabItem(1, Icons.currency_rupee, "Price"),
          _buildTabItem(2, Icons.location_on, "Location"),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    final theme = Theme.of(context);
    final isSelected = _currentTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _currentTabIndex = index);
          _pageController.animateToPage(
            index,
            duration: AppTheme.mediumDuration,
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: AppTheme.shortDuration,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
            isSelected ? AppTheme.primaryColor(theme) : Colors.transparent,
            borderRadius: AppTheme.mediumRadius,
            boxShadow: isSelected ? AppTheme.softShadow(theme) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: isSelected
                      ? AppTheme.textOnPrimary(theme)
                      : AppTheme.iconColor(theme),
                  size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? AppTheme.textOnPrimary(theme)
                      : AppTheme.textSecondary(theme),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    final theme = Theme.of(context);
    final buttonText = _currentTabIndex == 2 ? "Submit Details" : "Next";

    return Container(
      width: double.infinity,
      margin: AppTheme.mediumPadding,
      child: ElevatedButton(
        onPressed: _handleNextOrSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor(theme),
          foregroundColor: AppTheme.textOnPrimary(theme),
          padding: AppTheme.mediumPadding,
          shape: RoundedRectangleBorder(
            borderRadius: AppTheme.mediumRadius,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _currentTabIndex == 2 ? Icons.check_circle : Icons.arrow_forward,
              size: 20,
              color: AppTheme.textOnPrimary(theme),
            ),
            const SizedBox(width: 8),
            Text(
              buttonText,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textOnPrimary(theme),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: "Edit ${widget.categoryName}",
        onBack: () => Navigator.pop(context),
      ),
      body: Column(
        children: [
          _buildCustomTabBar(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentTabIndex = i),
              children: [
                DynamicFormScreen(
                  categoryName: widget.categoryName,
                  formConfig: widget.formConfig,
                  onChanged: (data) => _formData = data,
                ),
                PriceFormScreen(
                  onPriceSelected: (price) => _selectedPrice = price,
                ),
                LocationFormScreen(
                  onAddressSelected: (address, coordinates, locationDetails) {
                    _selectedAddress = address;
                    _selectedCoordinates = coordinates;
                    _locationDetails = locationDetails;
                  },
                  initialLocation: _selectedCoordinates,
                  initialAddress: _selectedAddress,
                  autoSaveToFirestore: false,
                ),
              ],
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }
}
