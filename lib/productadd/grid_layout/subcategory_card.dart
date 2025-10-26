import 'dart:ui';
import 'package:bargain/productadd/search_page_Activity/searchpage/searchpage.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SubcategoryCard extends StatefulWidget {
  final String subcategory;
  final double width;
  final double height;
  final bool isSelected;

  const SubcategoryCard({
    super.key,
    required this.subcategory,
    this.width = 140,
    this.height = 150,
    this.isSelected = false,
  });

  @override
  _SubcategoryCardState createState() => _SubcategoryCardState();
}

class _SubcategoryCardState extends State<SubcategoryCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String? _getAssetForSubcategory() {
    final Map<String, String> assetMap = {
      "Laptop": "assets/images/electronics/laptop.png",
      "Desktop": "assets/images/electronics/desktop.png",
      "Camera": "assets/images/electronics/camera.png",
      "Television": "assets/images/electronics/television.png",
      "Refrigerator": "assets/images/electronics/refrigerator.png",
      "Washing Machine": "assets/images/electronics/washing_machine.png",
      "Air Conditioner": "assets/images/electronics/air_conditioner.png",
      "Microwave": "assets/images/electronics/microwave.png",
      "Speaker": "assets/images/electronics/speaker.png",
      "Headphones": "assets/images/electronics/headphones.png",
      "Printer": "assets/images/electronics/printer.png",
      "Monitor": "assets/images/electronics/monitor.png",
      "Sofa": "assets/images/furniture/sofa.png",
      "Bed": "assets/images/furniture/bed.png",
      "Chair": "assets/images/furniture/chair.png",
      "Table": "assets/images/furniture/table.png",
      "Wardrobe": "assets/images/furniture/wardrobe.png",
      "Dining Table": "assets/images/furniture/dining_table.png",
      "Bookshelf": "assets/images/furniture/bookshelf.png",
      "Office Furniture": "assets/images/furniture/office_furniture.png",
      "Outdoor Furniture": "assets/images/furniture/outdoor_furniture.png",
      "Garden Furniture": "assets/images/furniture/garden_furniture.png",
      "Novels": "assets/images/books/novels.png",
      "Science Books": "assets/images/books/science_books.png",
      "Fiction Books": "assets/images/books/fiction_books.png",
      "Non-Fiction Books": "assets/images/books/non_fiction_books.png",
      "Storybooks": "assets/images/books/storybooks.png",
      "School Books": "assets/images/books/school_books.png",
      "Comics": "assets/images/books/comics.png",
      "Magazines": "assets/images/books/magazines.png",
      "Smartphone": "assets/images/mobiles/smartphone.png",
      "Tablet": "assets/images/mobiles/tablet.png",
      "Accessories": "assets/images/mobiles/accessories.png",
      "Earbuds": "assets/images/mobiles/earbuds.png",
      "Smartwatch": "assets/images/mobiles/smartwatch.png",
      "Power Bank": "assets/images/mobiles/power_bank.png",
      "Phone Case": "assets/images/mobiles/phone_case.png",
      "Screen Protector": "assets/images/mobiles/screen_protector.png",
      "Selfie Stick": "assets/images/mobiles/selfie_stick.png",
      "Memory Card": "assets/images/mobiles/memory_card.png",
      "Residential": "assets/images/properties/residential.png",
      "Commercial": "assets/images/properties/commercial.png",
      "Office": "assets/images/properties/office.png",
      "Land": "assets/images/properties/land.png",
      "PG / Hostel": "assets/images/properties/pg_hostel.png",
      "Car": "assets/images/vehicles/car.png",
      "Bike": "assets/subcatogery_images/Bike2.png",
      "Scooter": "assets/images/vehicles/scooter.png",
      "Truck": "assets/images/vehicles/truck.png",
      "Bus": "assets/images/vehicles/bus.png",
      "Auto Accessories": "assets/images/vehicles/auto_accessories.png",
      "Spare Parts": "assets/images/vehicles/spare_parts.png",
    };

    return assetMap[widget.subcategory.trim()];
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _animationController.forward().then((_) {
      _animationController.reverse();
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              SearchBarPage(query: widget.subcategory),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.28, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: AppTheme.mediumDuration,
        ),
      );
    });
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceColor(theme),
            AppTheme.surfaceColor(theme).withOpacity(0.85),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: AppTheme.textSecondary(theme).withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: AppTheme.textSecondary(theme).withOpacity(0.5),
                fontSize: 12,
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
    final assetPath = _getAssetForSubcategory();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovering = true),
            onExit: (_) => setState(() => _isHovering = false),
            child: GestureDetector(
              onTapDown: (_) => _animationController.forward(),
              onTapUp: (_) => _handleTap(),
              onTapCancel: () => _animationController.reverse(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppTheme.primaryColor(theme).withOpacity(0.08)
                      : AppTheme.cardColor(theme),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppTheme.primaryColor(theme)
                        : _isHovering
                        ? AppTheme.primaryColor(theme).withOpacity(0.28)
                        : AppTheme.borderColor(theme),
                    width: widget.isSelected ? 2.4 : 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isSelected
                          ? AppTheme.primaryColor(theme).withOpacity(0.18)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: widget.isSelected ? 12 : 8,
                      offset: Offset(0, widget.isSelected ? 6 : 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Container - Theme Color
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.surfaceColor(theme),
                              AppTheme.surfaceColor(theme).withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),

                      // Image Layer with Transparent Background Support
                      if (assetPath != null && assetPath.isNotEmpty)
                        Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.surfaceColor(theme),
                                    AppTheme.surfaceColor(theme).withOpacity(0.85),
                                  ],
                                ),
                              ),
                            ),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  assetPath,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => _buildPlaceholder(theme),
                                ),
                              ),
                            ),
                          ],
                        )




                      else
                        _buildPlaceholder(theme),

                      // Gradient Overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.56)
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),

                      // Text Label
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(theme).withOpacity(0.22),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Text(
                            widget.subcategory,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Selected Badge
                      if (widget.isSelected)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor(theme),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor(theme)
                                      .withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.check,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
