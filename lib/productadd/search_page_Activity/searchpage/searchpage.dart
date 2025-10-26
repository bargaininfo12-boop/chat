import 'package:bargain/productadd/grid_layout/ProductCard.dart';
import 'package:bargain/productadd/grid_layout/data_service.dart';
import 'package:bargain/productadd/grid_layout/image_model.dart';
import 'package:bargain/productadd/search_page_Activity/widgets/CustomSearchAppBar.dart';
import 'package:bargain/productadd/search_page_Activity/widgets/filter_bottom_sheet.dart';
import 'package:flutter/material.dart';

class SearchBarPage extends StatefulWidget {
  final String? query;
  final String? location;

  const SearchBarPage({super.key, this.query, this.location});

  @override
  State<SearchBarPage> createState() => _SearchBarPageState();
}

class _SearchBarPageState extends State<SearchBarPage> {
  final DataService _dataService = DataService.instance;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<ImageModel> _allImages = [];
  List<ImageModel> _filteredImages = [];

  bool _isLoading = true;
  String? _selectedLocation;
  List<String> _locationTags = [];
  List<String> _keywordTags = []; // Only one keyword allowed

  Map<String, String> _selectedFilters = {};
  String _selectedSort = 'Relevance';

  @override
  void initState() {
    super.initState();
    _initializeFromArgs();
    _subscribeToImages();
  }

  void _initializeFromArgs() {
    if (widget.query?.isNotEmpty == true) {
      _searchController.text = widget.query!;
      // Only take first keyword
      final firstKeyword = widget.query!.split(' ').firstWhere((s) => s.isNotEmpty, orElse: () => '');
      if (firstKeyword.isNotEmpty) {
        _keywordTags = [firstKeyword];
      }
    }
    if (widget.location?.isNotEmpty == true) {
      _locationController.text = widget.location!;
      _selectedLocation = widget.location!;
      _locationTags = [widget.location!];
    }
  }

  void _subscribeToImages() {
    // Subscribe to DataService stream — it will emit cached first, then live updates
    _dataService.getImages().listen((images) {
      if (!mounted) return;
      setState(() {
        _allImages = images;
        _applyLocalFilter();
        _isLoading = false;
      });
    }, onError: (err) {
      if (!mounted) return;
      setState(() {
        _allImages = [];
        _filteredImages = [];
        _isLoading = false;
      });
    });
  }

  void _applyLocalFilter() {
    // Use DataService.filterImages to centralize logic
    final result = _dataService.filterImages(
      location: _selectedLocation,
      keywords: _keywordTags,
      filters: _selectedFilters,
      sortOption: _selectedSort,
    );

    setState(() {
      _filteredImages = result;
    });
  }

  // 🔥 IMPROVED: Location Suggestions with smart matching
  Iterable<String> _getLocationSuggestions(String text) {
    if (text.trim().isEmpty) return const [];

    final lower = text.toLowerCase().trim();
    final exactMatches = <String>{};
    final partialMatches = <String>{};

    for (final img in _dataService.images) {
      final city = (img.city ?? '').trim();
      final state = (img.state ?? '').trim();

      if (city.isNotEmpty) {
        final cityLower = city.toLowerCase();
        if (cityLower == lower) {
          exactMatches.add(city);
        } else if (cityLower.startsWith(lower)) {
          exactMatches.add(city);
        } else if (cityLower.contains(lower)) {
          partialMatches.add(city);
        }
      }

      if (state.isNotEmpty) {
        final stateLower = state.toLowerCase();
        if (stateLower == lower) {
          exactMatches.add(state);
        } else if (stateLower.startsWith(lower)) {
          exactMatches.add(state);
        } else if (stateLower.contains(lower)) {
          partialMatches.add(state);
        }
      }

      // Early exit if we have enough matches
      if (exactMatches.length >= 5) break;
    }

    // Combine: exact matches first, then partial
    final combined = [...exactMatches, ...partialMatches];
    return combined.take(5);
  }

  // 🔥 IMPROVED: Keyword Suggestions with smart matching
  Iterable<String> _getKeywordSuggestions(String text) {
    if (text.trim().isEmpty) return const [];

    final lower = text.toLowerCase().trim();
    final exactMatches = <String>{};
    final partialMatches = <String>{};

    for (final img in _dataService.images) {
      final cat = img.category.trim();
      final sub = img.subcategory.trim();

      if (cat.isNotEmpty) {
        final catLower = cat.toLowerCase();
        if (catLower == lower) {
          exactMatches.add(cat);
        } else if (catLower.startsWith(lower)) {
          exactMatches.add(cat);
        } else if (catLower.contains(lower)) {
          partialMatches.add(cat);
        }
      }

      if (sub.isNotEmpty) {
        final subLower = sub.toLowerCase();
        if (subLower == lower) {
          exactMatches.add(sub);
        } else if (subLower.startsWith(lower)) {
          exactMatches.add(sub);
        } else if (subLower.contains(lower)) {
          partialMatches.add(sub);
        }
      }

      // Early exit if we have enough matches
      if (exactMatches.length >= 5) break;
    }

    // Combine: exact matches first, then partial
    final combined = [...exactMatches, ...partialMatches];
    return combined.take(5);
  }

  // Event handlers
  void _onLocationSelected(String loc) {
    setState(() {
      _selectedLocation = loc;
      _locationTags = [loc];
      _locationController.text = loc;
    });
    _applyLocalFilter();
  }

  void _onKeywordSelected(String kw) {
    if (kw.trim().isEmpty) return;
    // Replace existing keyword with new one (single keyword only)
    setState(() {
      _keywordTags = [kw]; // Replace, not add
      _searchController.clear();
    });
    _applyLocalFilter();
  }

  void _onLocationTagDeleted(String tag) {
    setState(() {
      _locationTags.remove(tag);
      _selectedLocation = null;
      _locationController.clear();
    });
    _applyLocalFilter();
  }

  void _onKeywordTagDeleted(String tag) {
    setState(() {
      _keywordTags.remove(tag);
      _searchController.clear();
    });
    _applyLocalFilter();
  }

  void _onApplyFilters(Map<String, String> filters) {
    setState(() {
      _selectedFilters = filters;
    });
    _applyLocalFilter();
  }

  bool get _canShowActions => _locationTags.isNotEmpty && _keywordTags.isNotEmpty;

  void _openFilterBottomSheet() {
    FilterBottomSheet.showConditionally(
      context: context,
      dataService: _dataService,
      selectedFilters: _selectedFilters,
      onApplyFilters: _onApplyFilters,
      // required additional params
      searchTerm: _searchController.text,
      selectedKeywords: _keywordTags,
      location: _selectedLocation ?? '',
      searchResultsData: _filteredImages,
    );
  }

  void _openSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
          ...['Relevance', 'Price: High to Low', 'Price: Low to High', 'Newest First']
              .map((e) => ListTile(
            title: Text(e),
            trailing: _selectedSort == e ? const Icon(Icons.check) : null,
            onTap: () {
              setState(() => _selectedSort = e);
              _applyLocalFilter();
              Navigator.pop(context);
            },
          ))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomSearchAppBar(
            locationController: _locationController,
            searchController: _searchController,
            locationTags: _locationTags,
            keywordTags: _keywordTags,
            onLocationSelected: _onLocationSelected,
            onKeywordSelected: _onKeywordSelected,
            onLocationTagDeleted: _onLocationTagDeleted,
            onKeywordTagDeleted: _onKeywordTagDeleted,
            locationSuggestionsBuilder: _getLocationSuggestions,
            keywordSuggestionsBuilder: _getKeywordSuggestions,
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_filteredImages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _locationTags.isEmpty || _keywordTags.isEmpty
                        ? Icons.search_off_rounded
                        : Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _locationTags.isEmpty || _keywordTags.isEmpty
                        ? 'Please select location and keywords to search'
                        : 'No results found',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_locationTags.isNotEmpty && _keywordTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Try adjusting your filters',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                ],
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _filteredImages.length,
              itemBuilder: (_, i) => ProductCard(imageModel: _filteredImages[i]),
            )),
          ),

          if (_canShowActions)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _openSortOptions,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sort, size: 18),
                          SizedBox(width: 6),
                          Text('Sort'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _openFilterBottomSheet,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.filter_alt_rounded, size: 18),
                          SizedBox(width: 6),
                          Text('Filter'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
