import 'package:flutter/material.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';

class FilterBottomSheet extends StatefulWidget {
  final DataService dataService;
  final Map<String, String> selectedFilters;
  final Function(Map<String, String>) onApplyFilters;
  final String searchTerm;
  final List<String> selectedKeywords;
  final String location;
  final List<ImageModel> searchResultsData;

  const FilterBottomSheet({
    super.key,
    required this.dataService,
    required this.selectedFilters,
    required this.onApplyFilters,
    required this.searchTerm,
    required this.selectedKeywords,
    required this.location,
    required this.searchResultsData,
  });

  static void showConditionally({
    required BuildContext context,
    required DataService dataService,
    required Map<String, String> selectedFilters,
    required Function(Map<String, String>) onApplyFilters,
    required String searchTerm,
    required List<String> selectedKeywords,
    required String location,
    required List<ImageModel> searchResultsData,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterBottomSheet(
        dataService: dataService,
        selectedFilters: selectedFilters,
        onApplyFilters: onApplyFilters,
        searchTerm: searchTerm,
        selectedKeywords: selectedKeywords,
        location: location,
        searchResultsData: searchResultsData,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Map<String, String> _filters;
  Map<String, Set<String>> _options = {};
  List<String> _categories = [];
  String _selectedCategory = '';

  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.selectedFilters);
    _prepareOptions();
  }

  void _prepareOptions() {
    final opts = <String, Set<String>>{};

    for (final img in widget.searchResultsData) {
      img.productDetails?.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          opts.putIfAbsent(key, () => <String>{}).add(value.toString().trim());
        }
      });
    }

    opts.remove('category');
    opts.remove('subcategory');
    opts.remove('location');
    opts.remove('description');

    opts['Price Range'] = {};

    _options = opts;
    _categories = opts.keys.toList();
    if (_categories.isNotEmpty) _selectedCategory = _categories.first;
  }

  void _applyFilters() {
    widget.onApplyFilters(_filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _filters.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
  }

  Widget _buildLeftPanel(ThemeData theme) {
    return Container(
      width: 140,
      color: AppTheme.surfaceColor(theme),
      child: ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = cat == _selectedCategory;
          return InkWell(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor(theme).withAlpha((0.08 * 255).toInt())
                    : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryColor(theme)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? AppTheme.primaryColor(theme)
                      : AppTheme.textPrimary(theme),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRightPanel(ThemeData theme) {
    if (_selectedCategory == 'Price Range') {
      return _buildPriceSection(theme);
    }

    final options = _options[_selectedCategory]?.toList() ?? [];
    if (options.isEmpty) {
      return Center(
        child: Text(
          "No options available",
          style: TextStyle(color: AppTheme.textSecondary(theme)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final opt = options[index];
        final isSelected = _filters[_selectedCategory] == opt;
        return CheckboxListTile(
          dense: true,
          activeColor: AppTheme.primaryColor(theme),
          contentPadding: EdgeInsets.zero,
          value: isSelected,
          title: Text(
            opt,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
              color: AppTheme.textPrimary(theme),
            ),
          ),
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _filters[_selectedCategory] = opt;
              } else {
                _filters.remove(_selectedCategory);
              }
            });
          },
        );
      },
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    final allPrices = widget.searchResultsData
        .map((img) => double.tryParse(img.price ?? '0') ?? 0.0)
        .toList();

    final double maxAvailablePrice = (allPrices.isNotEmpty)
        ? allPrices.reduce((a, b) => a > b ? a : b).toDouble()
        : 100000.0;

    double min = double.tryParse(_filters['minPrice'] ?? '0') ?? 0.0;
    double max = double.tryParse(_filters['maxPrice'] ?? '$maxAvailablePrice') ??
        maxAvailablePrice;

    // ✅ Clamp values to avoid RangeSlider crash
    min = min.clamp(0.0, maxAvailablePrice);
    max = max.clamp(min, maxAvailablePrice);

    _minPriceController.text = min.toInt().toString();
    _maxPriceController.text = max.toInt().toString();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Price Range",
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppTheme.textPrimary(theme),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min (₹)',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? 0.0;
                    setState(() {
                      _filters['minPrice'] = val.clamp(0.0, maxAvailablePrice).toString();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxPriceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max (₹)',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? maxAvailablePrice;
                    setState(() {
                      _filters['maxPrice'] = val.clamp(0.0, maxAvailablePrice).toString();
                    });
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          RangeSlider(
            values: RangeValues(min, max),
            min: 0.0,
            max: maxAvailablePrice,
            divisions: 50,
            activeColor: AppTheme.primaryColor(theme),
            labels: RangeLabels("₹${min.toInt()}", "₹${max.toInt()}"),
            onChanged: (v) {
              setState(() {
                _filters['minPrice'] = v.start.toInt().toString();
                _filters['maxPrice'] = v.end.toInt().toString();
              });
              _minPriceController.text = v.start.toInt().toString();
              _maxPriceController.text = v.end.toInt().toString();
            },
          ),

          Text(
            "₹${min.toInt()} - ₹${max.toInt()} (Max ₹${maxAvailablePrice.toInt()})",
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(ThemeData theme) {
    return SafeArea(
      child: Container(
        color: AppTheme.surfaceColor(theme),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.primaryColor(theme)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _clearFilters,
                child: Text(
                  "Clear All",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor(theme),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor(theme),
                  foregroundColor: AppTheme.textOnPrimary(theme),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _applyFilters,
                child: const Text(
                  "Apply",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(theme),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: AppTheme.mediumShadow(theme),
      ),
      child: Column(
        children: [
          SectionAppBar(
            title: "Filters",
            onBack: () => Navigator.pop(context),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                _buildLeftPanel(theme),
                Expanded(child: _buildRightPanel(theme)),
              ],
            ),
          ),
          _buildBottomButtons(theme),
        ],
      ),
    );
  }
}
