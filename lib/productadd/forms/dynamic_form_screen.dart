import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/productadd/add_product/data_holder.dart';

class DynamicFormScreen extends StatefulWidget {
  final String categoryName;
  final List<Map<String, dynamic>> formConfig;
  final Function(Map<String, String>)? onChanged;

  const DynamicFormScreen({
    super.key,
    required this.categoryName,
    required this.formConfig,
    this.onChanged,
  });

  @override
  State<DynamicFormScreen> createState() => _DynamicFormScreenState();
}

class _DynamicFormScreenState extends State<DynamicFormScreen> {
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String?> _dropdownValues = {};

  @override
  void initState() {
    super.initState();

    // ✅ Initialize all fields safely with defaults
    for (var field in widget.formConfig) {
      final label = field['label'] as String;
      final fieldType = field['type'] as String;
      final existingValue = DataHolder.details[label]?.toString();
      final defaultValue = field['default'] as String?;

      if (_isAutoFilledField(label)) {
        _textControllers[label] =
            TextEditingController(text: DataHolder.subcategory);
      } else if (fieldType == 'description') {
        _textControllers[label] =
            TextEditingController(text: DataHolder.description ?? "");
      } else if (fieldType == 'text' ||
          fieldType == 'number' ||
          fieldType == 'year') {
        _textControllers[label] =
            TextEditingController(text: existingValue ?? "");
      } else if (fieldType == 'dropdown') {
        _dropdownValues[label] =
            existingValue ?? defaultValue; // set default if not already
      }
    }
  }

  bool _isAutoFilledField(String label) {
    return label == "Device Type" ||
        label == "Property Type" ||
        label == "Vehicle Type" ||
        label == "Category";
  }

  /// ✅ Should this field be shown based on 'dependsOn'
  bool _shouldShowField(Map<String, dynamic> field) {
    final depends = field['dependsOn'];
    if (depends == null) return true;

    final depLabel = depends['label'] as String?;
    final depValue = depends['value'] as String?;
    if (depLabel == null || depValue == null) return true;

    final ctrl = _textControllers[depLabel];
    if (ctrl != null && ctrl.text.isNotEmpty) {
      return ctrl.text == depValue;
    }

    final dropValue = _dropdownValues[depLabel];
    if (dropValue != null && dropValue.isNotEmpty) {
      return dropValue == depValue;
    }

    return false;
  }

  Map<String, String> _collectFormData() {
    final formData = <String, String>{};

    _textControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty && key.toLowerCase() != "description") {
        formData[key] = controller.text;
      }
    });

    _dropdownValues.forEach((key, value) {
      if (value != null && value.isNotEmpty) {
        formData[key] = value;
      }
    });

    return formData;
  }

  void _emitFormData() {
    final collected = _collectFormData();
    DataHolder.details = collected;

    final descCtrl = _textControllers["Description"];
    if (descCtrl != null && descCtrl.text.trim().isNotEmpty) {
      DataHolder.description = descCtrl.text.trim();
    } else {
      DataHolder.description = null;
    }

    widget.onChanged?.call(collected);
    setState(() {}); // refresh dependent fields
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildField(Map<String, dynamic> field) {
    final theme = Theme.of(context);
    final label = field['label'] as String;
    final type = field['type'] as String;

    if (!_shouldShowField(field)) return const SizedBox.shrink();

    final baseDecoration = InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary(theme),
      ),
      border: OutlineInputBorder(
        borderRadius: AppTheme.mediumRadius,
        borderSide: BorderSide(color: AppTheme.borderColor(theme)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppTheme.mediumRadius,
        borderSide: BorderSide(color: AppTheme.borderColor(theme)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppTheme.mediumRadius,
        borderSide:
        BorderSide(color: AppTheme.primaryColor(theme), width: 2),
      ),
      filled: true,
      fillColor: AppTheme.inputFieldBackground(theme),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    // 🔒 Read-only auto-filled
    if (_isAutoFilledField(label)) {
      return TextFormField(
        controller: _textControllers[label],
        readOnly: true,
        style: theme.textTheme.bodyMedium
            ?.copyWith(color: AppTheme.textPrimary(theme)),
        decoration: baseDecoration.copyWith(
          prefixIcon: Icon(Icons.lock, color: AppTheme.iconColor(theme)),
        ),
      );
    }

    switch (type) {
      case 'text':
        return TextFormField(
          controller: _textControllers[label],
          onChanged: (_) => _emitFormData(),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textPrimary(theme)),
          decoration: baseDecoration.copyWith(
            prefixIcon: Icon(Icons.edit, color: AppTheme.iconColor(theme)),
          ),
        );

      case 'number':
        return TextFormField(
          controller: _textControllers[label],
          onChanged: (_) => _emitFormData(),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textPrimary(theme)),
          decoration: baseDecoration.copyWith(
            prefixIcon: Icon(Icons.pin, color: AppTheme.iconColor(theme)),
          ),
        );

      case 'year':
        return TextFormField(
          controller: _textControllers[label],
          onChanged: (_) => _emitFormData(),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
            LengthLimitingTextInputFormatter(4),
          ],
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textPrimary(theme)),
          decoration: baseDecoration.copyWith(
            prefixIcon: Icon(Icons.calendar_today,
                color: AppTheme.iconColor(theme)),
          ),
        );

      case 'dropdown':
        List<String> options = (field['options'] as List<String>);
        final defaultValue = field['default'] as String?;
        String? currentValue = _dropdownValues[label];

        // ✅ Prevent invalid value errors
        if (currentValue != null && !options.contains(currentValue)) {
          currentValue = null;
          _dropdownValues[label] = null;
        }

        // ✅ Apply default if nothing selected
        if (currentValue == null &&
            defaultValue != null &&
            options.contains(defaultValue)) {
          currentValue = defaultValue;
          _dropdownValues[label] = defaultValue;
        }

        return DropdownButtonFormField<String>(
          value: currentValue,
          decoration: baseDecoration.copyWith(
            prefixIcon: Icon(Icons.arrow_drop_down_circle,
                color: AppTheme.iconColor(theme)),
          ),
          dropdownColor: AppTheme.surfaceColor(theme),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textPrimary(theme)),
              ),
            ),
          )
              .toList(),
          onChanged: (value) {
            setState(() {
              _dropdownValues[label] = value;
            });
            _emitFormData();
          },
        );

      case 'description':
        return TextFormField(
          controller: _textControllers[label],
          onChanged: (_) => _emitFormData(),
          maxLines: 5,
          minLines: 3,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.textPrimary(theme)),
          decoration: baseDecoration.copyWith(
            hintText: "Write a clear and honest description...",
            alignLabelWithHint: true,
            prefixIcon: Icon(Icons.description_outlined,
                color: AppTheme.iconColor(theme)),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ Keep part fields just below "Selling Type"
    List<Map<String, dynamic>> sortedFields = List.from(widget.formConfig);
    final sellingType = _dropdownValues["Selling Type"];

    if (sellingType == "Spare/Part") {
      sortedFields.sort((a, b) {
        if (a['label'] == 'Selling Type') return -1;
        if (b['label'] == 'Selling Type') return 1;
        if (a['label'] == 'Part Name') return -1;
        if (b['label'] == 'Part Name') return 1;
        if (a['label'] == 'Part Condition') return -1;
        if (b['label'] == 'Part Condition') return 1;
        return 0;
      });
    }

    return SafeArea(
      child: Material(
        color: AppTheme.backgroundColor(theme),
        child: Padding(
          // ✅ Balanced screen padding
          padding:
          const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 24),
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: sortedFields.length,
            separatorBuilder: (_, __) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final field = sortedFields[index];
              final isFirstField = field['label'] == 'Selling Type';
              return AnimatedOpacity(
                opacity: _shouldShowField(field) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.only(
                    top: isFirstField ? 10 : 0, // ✅ Margin above Selling Type
                    bottom: _shouldShowField(field) ? 0 : 4,
                  ),
                  child: _buildField(field),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
