import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/chat/Chat_widgets/video_player_widget.dart';
import 'package:bargain/chat/Chat_widgets/FullScreenImagePage.dart';

class MediaCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> videoUrls;
  final double height;
  final bool autoPlayImages;

  const MediaCarousel({
    super.key,
    required this.imageUrls,
    required this.videoUrls,
    this.height = 450,
    this.autoPlayImages = true,
  });

  @override
  State<MediaCarousel> createState() => _MediaCarouselState();
}

class _MediaCarouselState extends State<MediaCarousel> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  int _currentIndex = 0;

  /// Combine images + videos into a unified list
  List<Map<String, String>> get _combinedMedia {
    final images = widget.imageUrls
        .map((u) => {'type': 'image', 'url': u})
        .toList();
    final videos = widget.videoUrls
        .map((u) => {'type': 'video', 'url': u})
        .toList();
    return [...images, ...videos];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaItems = _combinedMedia;

    if (mediaItems.isEmpty) {
      return _buildLocalNoMedia(theme);
    }

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: mediaItems.length,
          itemBuilder: (context, index, realIndex) {
            final media = mediaItems[index];
            final type = media['type'];
            final url = media['url'] ?? '';

            if (type == 'video') {
              return _buildVideoTile(url);
            } else {
              return _buildImageTile(theme, url);
            }
          },
          options: CarouselOptions(
            viewportFraction: 1.0,
            height: widget.height,
            autoPlay: widget.autoPlayImages &&
                mediaItems.length > 1 &&
                mediaItems.every((m) => m['type'] == 'image'),
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) =>
                setState(() => _currentIndex = index),
            enableInfiniteScroll: mediaItems.length > 1,
          ),
          carouselController: _carouselController,
        ),

        if (mediaItems.length > 1) _buildIndicator(theme, mediaItems.length),
        _buildCounter(theme, mediaItems.length),
      ],
    );
  }

  // ---------------- VIDEO TILE ----------------
  Widget _buildVideoTile(String url) {
    if (url.isEmpty) return _buildFallbackVideo();

    return SimpleVideoPlayerWidget(
      videoUrl: url,
      autoPlay: false,
      lazyInit: true,
      enableFullScreen: true,
      heroTag: url,
    );
  }

  Widget _buildFallbackVideo() {
    return Container(
      color: Colors.black12,
      child: const Center(
        child: Icon(Icons.videocam_off, size: 60, color: Colors.grey),
      ),
    );
  }

  // ---------------- IMAGE TILE ----------------
  Widget _buildImageTile(ThemeData theme, String url) {
    if (url.isEmpty) return _buildLocalFallbackImage(theme);

    return GestureDetector(
      onTap: () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FullScreenMediaPage(
              mediaUrl: url,
              isImage: true,
              heroTag: url,
            ),
          ),
        );
      },
      child: CachedNetworkImage(
        imageUrl: url,
        cacheManager: CustomCacheManager.instance, // ✅ unified cache usage
        fit: BoxFit.cover,
        width: double.infinity,
        height: widget.height,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, _) => Shimmer.fromColors(
          baseColor: AppTheme.shimmerBaseColor(theme),
          highlightColor: AppTheme.shimmerHighlightColor(theme),
          child: Container(
            color: AppTheme.surfaceColor(theme),
            width: double.infinity,
            height: widget.height,
          ),
        ),
        errorWidget: (context, _, __) => _buildLocalFallbackImage(theme),
      ),
    );
  }

  // ---------------- LOCAL FALLBACKS ----------------
  Widget _buildLocalFallbackImage(ThemeData theme) {
    return Container(
      color: AppTheme.surfaceColor(theme),
      height: widget.height,
      child: Center(
        child: Image.asset(
          'assets/images/no_image.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildLocalNoMedia(ThemeData theme) {
    return Container(
      height: widget.height,
      color: AppTheme.surfaceColor(theme),
      child: Center(
        child: Image.asset(
          'assets/images/no_image.png',
          width: 140,
          height: 140,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // ---------------- PAGE INDICATOR ----------------
  Widget _buildIndicator(ThemeData theme, int count) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: count,
          effect: WormEffect(
            activeDotColor: AppTheme.primaryAccent(theme),
            dotColor:
            AppTheme.textSecondary(theme).withOpacity(0.5),
            dotHeight: 8,
            dotWidth: 8,
          ),
        ),
      ),
    );
  }

  // ---------------- COUNTER ----------------
  Widget _buildCounter(ThemeData theme, int count) {
    if (count <= 1) return const SizedBox.shrink();
    return Positioned(
      top: 20,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.loadingOverlayColor(theme),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentIndex + 1} / $count',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textPrimary(theme),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
