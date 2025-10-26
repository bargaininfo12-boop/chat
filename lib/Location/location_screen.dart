// File: lib/Location/location_screen.dart

import 'package:bargain/Location/location_service.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  LocationScreenState createState() => LocationScreenState();
}

class LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Location Controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocationLoading = false;
  String? _locationMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    LocationService.initialize();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserLocation() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _addressController.text = data?['address'] ?? '';
          _cityController.text = data?['city'] ?? '';
          _stateController.text = data?['state'] ?? '';
          _pinCodeController.text = data?['pinCode'] ?? '';
        });
      }
    } catch (e) {
      _showError("Error loading location data");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);

    try {
      final result = await LocationService.getFullLocationData();

      if (result.isSuccess) {
        final locationData = result.data!;
        setState(() {
          _addressController.text = locationData.address;
          _cityController.text = locationData.city;
          _stateController.text = locationData.state;
          _pinCodeController.text = locationData.pinCode;
          _locationMessage = "Location fetched successfully";
        });
      } else {
        setState(() {
          _locationMessage = result.errorMessage ?? 'Error getting location';
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Error getting location: $e';
      });
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _saveLocation() async {
    if (!_validateLocation()) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      if (_currentUser != null) {
        final locationData = {
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'state': _stateController.text.trim(),
          'pinCode': _pinCodeController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update(locationData);

        if (mounted) {
          _showSuccess("Address updated successfully");
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError("Error saving address: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _validateLocation() {
    return _addressController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _stateController.text.trim().isNotEmpty &&
        _pinCodeController.text.trim().isNotEmpty &&
        RegExp(r'^\d{6}$').hasMatch(_pinCodeController.text.trim());
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.errorColor(Theme.of(context)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.successColor(Theme.of(context)),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLength: maxLength,
        style: TextStyle(color: AppTheme.textPrimary(Theme.of(context))),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.iconColor(Theme.of(context))),
          filled: true,
          fillColor: AppTheme.inputFieldBackground(Theme.of(context)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.borderColor(Theme.of(context))),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primaryColor(Theme.of(context)), width: 2),
          ),
          counterText: '',
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
        title: "Address",
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor(theme),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Update your address",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(theme),
                  )),
              const SizedBox(height: 8),
              Text(
                "Keep your location up to date for better experience",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary(theme),
                ),
              ),
              const SizedBox(height: 24),

              // Get Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLocationLoading ? null : _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isLocationLoading
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.location_searching),
                  label: Text(
                    _isLocationLoading
                        ? "Getting Location..."
                        : "Get Current Location",
                  ),
                ),
              ),

              if (_locationMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor(theme).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.successColor(theme).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppTheme.successColor(theme), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.successColor(theme),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text("Or enter manually:",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary(theme),
                  )),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                label: "Address",
                hint: "Enter your address",
                icon: Icons.location_on_outlined,
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: "City",
                      hint: "Enter city",
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: "State",
                      hint: "Enter state",
                      icon: Icons.map_outlined,
                    ),
                  ),
                ],
              ),

              _buildTextField(
                controller: _pinCodeController,
                label: "Pin Code",
                hint: "Enter 6-digit pin code",
                icon: Icons.pin_drop_outlined,
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _saveLocation,
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text("Update Address"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
