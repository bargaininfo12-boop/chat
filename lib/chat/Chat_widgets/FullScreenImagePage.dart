// v0.5-full_screen_media_page · 2025-10-25T09:30 IST
// full_screen_media_page.dart
//
// Full screen viewer for image & video.
// - Image: PhotoView with CachedNetworkImageProvider (uses CustomCacheManager.fileCache).
// - Video: uses VideoPlayerController; if controller not provided it creates one from mediaUrl.
// - Handles orientation and system UI mode cleanly.
// - Supports heroTag for image transitions.

import 'dart:io';

import 'package:bargain/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

import '../utils/custom_cache_manager.dart';

class FullScreenMediaPage extends StatefulWidget {
  final VideoPlayerController? controller; // optional external controller (reused)
  final String? mediaUrl; // required if controller not provided
  final String? heroTag;
  final bool isImage; // true => image, false => video
  final bool autoPlay;

  const FullScreenMediaPage({
    super.key,
    this.controller,
    this.mediaUrl,
    this.heroTag,
    this.isImage = false,
    this.autoPlay = false,
  });

  @override
  State<FullScreenMediaPage> createState() => _FullScreenMediaPageState();
}

class _FullScreenMediaPageState extends State<FullScreenMediaPage> with WidgetsBindingObserver {
  VideoPlayerController? _internalController;
  bool _ownsController = false;
  bool _controllerInitialized = false;
  bool _isBuffering = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Enter immersive mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!widget.isImage) {
      // video: ensure we have a controller
      if (widget.controller != null) {
        _internalController = widget.controller;
        _ownsController = false;
        _initControllerReuse();
      } else {
        _ownsController = true;
        _createControllerFromUrlOrFile();
      }

      // lock landscape for video
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    }
  }

  Future<void> _initControllerReuse() async {
    try {
      await _internalController!.initialize();
      setState(() {
        _controllerInitialized = true;
      });
      if (widget.autoPlay) _internalController!.play();
      _internalController!.addListener(_onControllerUpdate);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _createControllerFromUrlOrFile() async {
    final src = widget.mediaUrl;
    if (src == null) {
      // nothing to play
      return;
    }
    try {
      if (_isLocalPath(src)) {
        _internalController = VideoPlayerController.file(File(_normalizeLocalPath(src)));
      } else {
        _internalController = VideoPlayerController.network(src);
      }
      await _internalController!.initialize();
      setState(() {
        _controllerInitialized = true;
      });
      _internalController!.addListener(_onControllerUpdate);
      if (widget.autoPlay) _internalController!.play();
    } catch (e) {
      // initialization failed
      setState(() {
        _controllerInitialized = false;
      });
    }
  }

  void _onControllerUpdate() {
    final cont = _internalController;
    if (cont == null) return;
    final buffering = cont.value.isBuffering;
    if (buffering != _isBuffering) {
      setState(() => _isBuffering = buffering);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Restore portrait orientations & system UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    if (_ownsController) {
      try {
        _internalController?.removeListener(_onControllerUpdate);
        _internalController?.pause();
        _internalController?.dispose();
      } catch (_) {}
    } else {
      // if we reused external controller, just remove listener
      try {
        widget.controller?.removeListener(_onControllerUpdate);
      } catch (_) {}
    }
    super.dispose();
  }

  // Keep playback paused when app goes background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_internalController == null) return;
    if (state == AppLifecycleState.paused) {
      try {
        _internalController!.pause();
      } catch (_) {}
    }
    super.didChangeAppLifecycleState(state);
  }

  bool _isLocalPath(String s) {
    return s.startsWith('/') || s.startsWith('file://');
  }

  String _normalizeLocalPath(String s) => s.replaceFirst('file://', '');

  Widget _buildImage(ThemeData theme) {
    final url = widget.mediaUrl;
    if (url == null || url.isEmpty) {
      return _buildLocalFallback(theme);
    }

    final isLocal = _isLocalPath(url);
    final ImageProvider provider = isLocal
        ? FileImage(File(_normalizeLocalPath(url)))
        : CachedNetworkImageProvider(url, cacheManager: CustomCacheManager.fileCache);

    return PhotoView(
      imageProvider: provider,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.contained * 3.0,
      heroAttributes: widget.heroTag != null ? PhotoViewHeroAttributes(tag: widget.heroTag!) : null,
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildLocalFallback(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, size: 72, color: AppTheme.textSecondary(theme)),
          const SizedBox(height: 12),
          Text('Media not available', style: TextStyle(color: AppTheme.textSecondary(theme))),
        ],
      ),
    );
  }

  Widget _buildVideo(ThemeData theme) {
    if (!_controllerInitialized || _internalController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _internalController!;
    return GestureDetector(
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          ),

          // buffering indicator
          if (_isBuffering) const CircularProgressIndicator(),

          // big play/pause icon
          if (_showControls && !controller.value.isPlaying)
            const Icon(Icons.play_circle_fill, size: 80, color: Colors.white70),

          // bottom controls
          if (_showControls)
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: _buildBottomControls(controller, theme),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(VideoPlayerController controller, ThemeData theme) {
    final duration = controller.value.duration;
    final pos = controller.value.position;
    final totalSec = duration.inSeconds > 0 ? duration.inSeconds : 1;
    final played = pos.inSeconds.clamp(0, totalSec);
    final progress = played / totalSec;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // seek bar
        Slider(
          value: progress.clamp(0.0, 1.0),
          onChanged: (v) {
            final seekPos = Duration(milliseconds: (v * duration.inMilliseconds).toInt());
            controller.seekTo(seekPos);
          },
          activeColor: theme.colorScheme.secondary,
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
                setState(() {});
              },
              icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
            ),
            Text(_formatDuration(pos), style: const TextStyle(color: Colors.white, fontSize: 12)),
            const SizedBox(width: 8),
            Text('/', style: const TextStyle(color: Colors.white70)),
            const SizedBox(width: 8),
            Text(_formatDuration(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const Spacer(),
            IconButton(
              onPressed: () {
                // toggle mute
                final vol = controller.value.volume;
                controller.setVolume(vol > 0 ? 0.0 : 1.0);
                setState(() {});
              },
              icon: Icon(
                controller.value.volume > 0 ? Icons.volume_up : Icons.volume_off,
                color: Colors.white,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
            )
          ],
        )
      ],
    );
  }

  String _formatDuration(Duration d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    final h = d.inHours;
    if (h > 0) return '${two(h)}:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.isImage ? 'Image' : 'Video', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: widget.isImage ? _buildImage(theme) : _buildVideo(theme),
      ),
    );
  }
}
