import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ImagePagerAdapter extends StatefulWidget {
  final List<String> imageUrls;
  final List<String> videoUrls;

  const ImagePagerAdapter({
    super.key,
    required this.imageUrls,
    required this.videoUrls,
  });

  @override
  State<ImagePagerAdapter> createState() => _ImagePagerAdapterState();
}

class _ImagePagerAdapterState extends State<ImagePagerAdapter> {
  final List<VideoPlayerController> _videoControllers = [];

  @override
  void initState() {
    super.initState();

    // Initialize all video controllers
    for (final url in widget.videoUrls) {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
      _videoControllers.add(controller);
    }
  }

  @override
  void dispose() {
    for (final controller in _videoControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = [
      ...widget.imageUrls.map((url) => {'type': 'image', 'url': url}),
      ...widget.videoUrls.map((url) => {'type': 'video', 'url': url}),
    ];

    if (allItems.isEmpty) {
      return const Center(child: Text("No media available"));
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 400,
        viewportFraction: 1.0,
        enableInfiniteScroll: false,
        enlargeCenterPage: false,
      ),
      items: allItems.map((item) {
        if (item['type'] == 'image') {
          return Builder(
            builder: (context) {
              return Image.network(
                item['url']!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.broken_image, size: 40),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              );
            },
          );
        } else {
          final index =
          widget.videoUrls.indexWhere((url) => url == item['url']);
          final controller =
          (index >= 0 && index < _videoControllers.length)
              ? _videoControllers[index]
              : null;

          if (controller == null || !controller.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                controller.value.isPlaying
                    ? controller.pause()
                    : controller.play();
              });
            },
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          );
        }
      }).toList(),
    );
  }
}
