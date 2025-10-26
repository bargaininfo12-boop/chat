// File: lib/screens/user_setup_page.dart
// ✅ Synced with updated UserService (v2.2.0)

import 'package:bargain/Database/database_helper.dart';
import 'package:bargain/Location/location_service.dart';
import 'package:bargain/Services/user_service.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/homesceen/home_page.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class UserSetupPage extends StatefulWidget {
  final User user;
  const UserSetupPage({super.key, required this.user});

  @override
  State<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends State<UserSetupPage> {
  final _pageController = PageController();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLocationLoading = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    LocationService.initialize();
    _prefillUserData();
  }

  Future<void> _prefillUserData() async {
    try {
      final user = widget.user;
      final localUser = await DatabaseHelper.instance.getUser(user.uid);
      setState(() {
        _nameController.text = user.displayName ?? localUser?.name ?? '';
        _emailController.text = user.email ?? localUser?.email ?? '';
        _phoneController.text =
            user.phoneNumber?.replaceAll('+91', '') ?? localUser?.phoneNumber ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Error loading data: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocationLoading = true);
    try {
      final result = await LocationService.getFullLocationData();
      if (result.isSuccess) {
        final loc = result.data!;
        setState(() {
          _addressController.text = loc.address;
          _cityController.text = loc.city;
          _stateController.text = loc.state;
          _pinController.text = loc.pinCode;
          _locationMessage = "📍 Location fetched successfully!";
        });
      } else {
        _locationMessage = result.errorMessage ?? 'Location fetch failed';
      }
    } catch (e) {
      _locationMessage = 'Error getting location: $e';
    } finally {
      setState(() => _isLocationLoading = false);
    }
  }

  // ✅ Now uses updateUserProfile() instead of saveBasicDetails/saveLocationData
  Future<void> _saveAndFinish() async {
    if (!_validateCurrentStep()) return;

    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        _showError("No logged-in user found.");
        return;
      }

      // ensure initialized
      await userService.initializeUser(firebaseUser);

      // ✅ Combine both steps in single update
      final updated = await userService.updateUserProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pinCode: _pinController.text.trim(),
      );

      // FCM token ensure
      await FirebaseAuthService.instance.saveUserFCMToken();

      if (updated) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomePage(user: widget.user)),
              (route) => false,
        );
      } else {
        _showError("Failed to update profile");
      }
    } catch (e) {
      _showError("Error saving user setup: $e");
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ✅ Step navigation
  void _nextStep() {
    if (_validateCurrentStep()) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ✅ Validation methods
  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _validateName(_nameController.text) == null &&
          _validateEmail(_emailController.text) == null &&
          _validatePhone(_phoneController.text) == null;
    } else {
      return _addressController.text.isNotEmpty &&
          _cityController.text.isNotEmpty &&
          _stateController.text.isNotEmpty &&
          _pinController.text.isNotEmpty;
    }
  }

  String? _validateName(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Name required' : null;

  String? _validateEmail(String? v) =>
      (v == null || !RegExp(r"^[^@]+@[^@]+\.[^@]+").hasMatch(v.trim()))
          ? 'Invalid email'
          : null;

  String? _validatePhone(String? v) =>
      (v == null || !RegExp(r'^[6-9]\d{9}$').hasMatch(v.trim()))
          ? 'Invalid phone number'
          : null;

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor(Theme.of(context)),
      ),
    );
  }

  // ✅ UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(Theme.of(context)),
      appBar: AppBar(
        title: const Text('Account Setup'),
        backgroundColor: AppTheme.appBarBackground(Theme.of(context)),
        leading: _currentStep > 0
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _previousStep,
        )
            : null,
      ),
      body: _isLoading
          ? Center(
          child: CircularProgressIndicator(
              color: AppTheme.primaryColor(Theme.of(context))))
          : Column(
        children: [
          LinearProgressIndicator(
            value: (_currentStep + 1) / 2,
            color: AppTheme.primaryColor(Theme.of(context)),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPersonalStep(),
                _buildLocationStep(),
              ],
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildPersonalStep() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        _buildTextField(
          _nameController,
          'Full Name',
          Icons.person_outline,
          _validateName,
        ),
        _buildTextField(
          _emailController,
          'Email Address',
          Icons.email_outlined,
          _validateEmail,
        ),
        _buildTextField(
          _phoneController,
          'Phone Number',
          Icons.phone_outlined,
          _validatePhone,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          formatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    ),
  );

  Widget _buildLocationStep() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLocationLoading ? null : _getCurrentLocation,
          icon: const Icon(Icons.my_location),
          label: Text(
              _isLocationLoading ? 'Getting Location...' : 'Use Current Location'),
        ),
        if (_locationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_locationMessage!,
                style: TextStyle(
                    color: AppTheme.successColor(Theme.of(context)))),
          ),
        _buildTextField(_addressController, 'Address',
            Icons.location_on_outlined, null),
        _buildTextField(_cityController, 'City', Icons.location_city_outlined, null),
        _buildTextField(_stateController, 'State', Icons.map_outlined, null),
        _buildTextField(_pinController, 'Pin Code', Icons.pin_drop_outlined, null,
            keyboardType: TextInputType.number,
            maxLength: 6,
            formatters: [FilteringTextInputFormatter.digitsOnly]),
      ],
    ),
  );

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      String? Function(String?)? validator, {
        TextInputType? keyboardType,
        int? maxLength,
        List<TextInputFormatter>? formatters,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        maxLength: maxLength,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildBottomButtons() => Padding(
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Back'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentStep == 0 ? 1 : 2,
          child: ElevatedButton(
            onPressed:
            _isSaving ? null : (_currentStep == 0 ? _nextStep : _saveAndFinish),
            child: _isSaving
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_currentStep == 0 ? 'Next' : 'Complete Setup'),
          ),
        ),
      ],
    ),
  );
}
