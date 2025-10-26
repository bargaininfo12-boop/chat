import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PriceFormScreen extends StatefulWidget {
  final Function(String) onPriceSelected;
  const PriceFormScreen({required this.onPriceSelected, super.key});

  @override
  State<PriceFormScreen> createState() => _PriceFormScreenState();
}

class _PriceFormScreenState extends State<PriceFormScreen> {
  final TextEditingController _priceController = TextEditingController();
  double _price = 100;
  final double _minPrice = 50;
  final double _maxPrice = 200000000; // 200 Crore
  final FocusNode _focusNode = FocusNode();
  bool _isUpdatingFromSlider = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = _price.toStringAsFixed(0);
    widget.onPriceSelected(_price.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _priceController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ✅ Helper — Format ₹ in Indian style (₹1,00,000)
  String _formatIndianCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(value);
  }

  // ✅ Helper — Convert number into words (Indian format)
  String _convertNumberToWords(double number) {
    final n = number.toInt();
    if (n == 0) return "Zero Rupees";

    final units = [
      "",
      "One",
      "Two",
      "Three",
      "Four",
      "Five",
      "Six",
      "Seven",
      "Eight",
      "Nine",
      "Ten",
      "Eleven",
      "Twelve",
      "Thirteen",
      "Fourteen",
      "Fifteen",
      "Sixteen",
      "Seventeen",
      "Eighteen",
      "Nineteen"
    ];
    final tens = [
      "",
      "",
      "Twenty",
      "Thirty",
      "Forty",
      "Fifty",
      "Sixty",
      "Seventy",
      "Eighty",
      "Ninety"
    ];

    String twoDigits(int num) {
      if (num < 20) return units[num];
      final ten = num ~/ 10;
      final unit = num % 10;
      return "${tens[ten]}${unit > 0 ? " ${units[unit]}" : ""}";
    }

    String convertSection(int num, String suffix) {
      if (num == 0) return "";
      return "${twoDigits(num)} $suffix ";
    }

    final crore = n ~/ 10000000;
    final lakh = (n ~/ 100000) % 100;
    final thousand = (n ~/ 1000) % 100;
    final hundred = (n ~/ 100) % 10;
    final remainder = n % 100;

    String result = "";
    if (crore > 0) result += convertSection(crore, "Crore");
    if (lakh > 0) result += convertSection(lakh, "Lakh");
    if (thousand > 0) result += convertSection(thousand, "Thousand");
    if (hundred > 0) result += "${units[hundred]} Hundred ";
    if (remainder > 0) result += twoDigits(remainder);

    return "$result Rupees".trim();
  }

  void _updatePrice(double newPrice) {
    _isUpdatingFromSlider = true;
    setState(() {
      _price = newPrice.clamp(_minPrice, 50000); // Slider max = 50,000
      _priceController.text = _price.toStringAsFixed(0);
    });
    widget.onPriceSelected(_price.toStringAsFixed(0));
    _isUpdatingFromSlider = false;
  }

  void _onTextFieldChanged(String value) {
    if (_isUpdatingFromSlider) return;

    if (value.isNotEmpty) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        setState(() => _price = parsed.clamp(_minPrice, _maxPrice));
        widget.onPriceSelected(_price.toStringAsFixed(0));
      }
    } else {
      setState(() => _price = _minPrice);
      widget.onPriceSelected(_price.toStringAsFixed(0));
    }
  }

  String? _validatePrice(String? value) {
    if (value == null || value.isEmpty) return 'Price cannot be empty';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    if (parsed < _minPrice || parsed > _maxPrice) {
      return 'Must be between ₹${_formatIndianCurrency(_minPrice)} and ₹${_formatIndianCurrency(_maxPrice)}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Price',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 Price Input
              TextFormField(
                controller: _priceController,
                focusNode: _focusNode,
                keyboardType: const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                validator: _validatePrice,
                decoration: InputDecoration(
                  labelText: 'Price (in INR)',
                  labelStyle: TextStyle(color: theme.colorScheme.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLowest,
                  prefixIcon: Icon(Icons.currency_rupee, color: theme.colorScheme.primary),
                  suffixIcon: _priceController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () {
                      _priceController.clear();
                      setState(() => _price = _minPrice);
                      widget.onPriceSelected(_price.toStringAsFixed(0));
                    },
                  )
                      : null,
                ),
                onChanged: _onTextFieldChanged,
              ),

              const SizedBox(height: 20),

              // 🔹 Selected price (numeric + in words)
              Text(
                'Selected: ${_formatIndianCurrency(_price)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _convertNumberToWords(_price),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                ),
                child: Slider(
                  value: _price.clamp(_minPrice, 50000),
                  min: _minPrice,
                  max: 50000,
                  divisions: 100,
                  label: _formatIndianCurrency(_price),
                  onChanged: _updatePrice,
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Quick Select Buttons
              Wrap(
                spacing: 8.0,
                children: [
                  _buildPresetButton(context, 500),
                  _buildPresetButton(context, 1000),
                  _buildPresetButton(context, 5000),
                  _buildPresetButton(context, 10000),
                  _buildPresetButton(context, 25000),
                  _buildPresetButton(context, 50000),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, double price) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(_formatIndianCurrency(price)),
      selected: _price == price,
      onSelected: (selected) {
        if (selected) _updatePrice(price);
      },
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }
}
