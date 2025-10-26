import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bargain/Location/location_models.dart';
import 'package:bargain/Location/location_service.dart';

class LocationFormScreen extends StatefulWidget {
  final Function(String, LatLng?, Map<String, String>?) onAddressSelected;
  final LatLng? initialLocation;
  final bool autoSaveToFirestore;
  final String? initialAddress;

  const LocationFormScreen({
    super.key,
    required this.onAddressSelected,
    this.initialLocation,
    this.autoSaveToFirestore = false,
    this.initialAddress,
  });

  @override
  State<LocationFormScreen> createState() => _LocationFormScreenState();
}

class _LocationFormScreenState extends State<LocationFormScreen>
    with TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _addressFocusNode = FocusNode();
  final GlobalKey _textFieldKey = GlobalKey();

  Set<Marker> _markers = {};
  List<PlaceSuggestion> _suggestions = [];
  OverlayEntry? _overlayEntry;
  Timer? _debounceTimer;

  bool _isLoading = false;
  bool _isLoadingSuggestions = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const LatLng _defaultLocation = LatLng(28.6139, 77.2090);
  static const Duration _debounceDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward().then((_) {
      if (mounted) _slideController.forward();
    });

    LocationService.initialize();

    if (widget.initialAddress != null) {
      _addressController.text = widget.initialAddress!;
    }
    if (widget.initialLocation != null) {
      _updateSelectedPosition(widget.initialLocation!);
    }

    _addressFocusNode.addListener(() {
      if (_addressFocusNode.hasFocus && _addressController.text.isNotEmpty) {
        _fetchSuggestions(_addressController.text);
      } else {
        _hideSuggestions();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _addressController.dispose();
    _addressFocusNode.dispose();
    _debounceTimer?.cancel();
    _hideSuggestions();
    super.dispose();
  }

  void _setLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  Future<void> _updateSelectedPosition(LatLng position) async {
    if (!mounted) return;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet:
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          ),
        ),
      };
    });

    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(position, 16));
  }

  void _onAddressChanged(String input) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () {
      if (input.length > 2 && _addressFocusNode.hasFocus) {
        _fetchSuggestions(input);
      } else {
        _hideSuggestions();
      }
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    if (!mounted) return;
    setState(() => _isLoadingSuggestions = true);

    _showSuggestionOverlay();

    final result = await LocationService.getPlaceSuggestions(input);
    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _suggestions = result.data ?? []);
    } else {
      setState(() => _suggestions = []);
    }

    setState(() => _isLoadingSuggestions = false);
  }

  Future<void> _selectPlace(PlaceSuggestion suggestion) async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    _hideSuggestions();
    _addressController.text = suggestion.description;
    _addressFocusNode.unfocus();
    _setLoading(true);

    final details = await LocationService.getPlaceDetails(suggestion.placeId);
    if (!mounted) return;

    if (details.isSuccess) {
      final place = details.data!;
      await _updateLocationData(place.coordinates,
          successMessage: '✓ Location selected successfully');
    } else {
      _showMessage('Failed to get location details', isError: true);
    }
    _setLoading(false);
  }

  Future<void> _updateLocationData(LatLng position,
      {String? successMessage}) async {
    await _updateSelectedPosition(position);

    final pos = Position(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0,
      altitudeAccuracy: 1.0,
      heading: 0,
      headingAccuracy: 1.0,
      speed: 0,
      speedAccuracy: 0,
    );

    final addressResult = await LocationService.getAddressFromCoordinates(pos);
    if (!mounted) return;

    if (addressResult.isSuccess) {
      _addressController.text = addressResult.address ?? '';
      if (successMessage != null) _showMessage(successMessage);
      widget.onAddressSelected(
        addressResult.address ?? '',
        position,
        addressResult.toMap(),
      );
    } else {
      _showMessage('Failed to fetch address', isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor:
        isError ? Colors.red.withValues(alpha: 0.9) : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 24),
                  _buildSearchCard(theme),
                  const SizedBox(height: 20),
                  _buildMapCard(theme, screenHeight),
                  const SizedBox(height: 20),
                  _buildGradientLocationButton(theme), // 👈 your fancy button
                  const SizedBox(height: 12),
                  _buildHelpText(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.location_on, color: theme.colorScheme.onPrimary),
      ),
      const SizedBox(width: 16),
      Text('Select Location',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          )),
    ],
  );

  Widget _buildSearchCard(ThemeData theme) => Container(
    decoration: BoxDecoration(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      key: _textFieldKey,
      controller: _addressController,
      focusNode: _addressFocusNode,
      onChanged: _onAddressChanged,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: 'Search area, street, landmark...',
        prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
        filled: true,
        fillColor:
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _buildMapCard(ThemeData theme, double screenHeight) => Container(
    height: screenHeight * 0.35,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialLocation ?? _defaultLocation,
        zoom: 14,
      ),
      onMapCreated: (controller) {
        if (!_mapController.isCompleted) _mapController.complete(controller);
      },
      markers: _markers,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      liteModeEnabled: true,
    ),
  );

  // 👇 Restored your original gradient-styled location button
  Widget _buildGradientLocationButton(ThemeData theme) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      icon: Icon(Icons.my_location, color: theme.colorScheme.onPrimary),
      label: Text(
        'Use Current Location',
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: _isLoading ? null : _handleCurrentLocation,
    ),
  );

  Future<void> _handleCurrentLocation() async {
    HapticFeedback.mediumImpact();
    _setLoading(true);

    final permissionResult = await LocationService.checkLocationPermission();

    if (!permissionResult.granted) {
      _setLoading(false);
      if (permissionResult.openSettings) {
        _showPermissionDialog(permissionResult.message);
      } else if (permissionResult.canRetry) {
        _showMessage(permissionResult.message, isError: true);
      }
      return;
    }

    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      await _updateLocationData(
        LatLng(position.latitude, position.longitude),
        successMessage: '✓ Location updated successfully',
      );
    } else {
      _showMessage('Unable to get your location', isError: true);
    }

    _setLoading(false);
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Permission Required'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText(ThemeData theme) => Center(
    child: Text(
      'Tap on the map or search to select your location',
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    ),
  );

  void _showSuggestionOverlay() {
    if (_overlayEntry != null) return;
    final renderBox =
    _textFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 16,
        top: offset.dy + size.height + 8,
        width: size.width - 32,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _suggestions.length,
            itemBuilder: (context, i) {
              final s = _suggestions[i];
              return ListTile(
                leading: Icon(Icons.location_on,
                    color: Theme.of(context).colorScheme.primary),
                title: Text(s.description),
                onTap: () async {
                  _overlayEntry?.remove();
                  _overlayEntry = null;
                  await _selectPlace(s);
                },
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideSuggestions() {
    _debounceTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
