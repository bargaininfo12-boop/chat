import 'dart:async';
import 'dart:io';
import 'package:bargain/chat/utils/custom_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bargain/chat/Chat_widgets/FullScreenImagePage.dart' show FullScreenMediaPage;
import 'package:bargain/app_theme/app_theme.dart';

/// 🔹 GlobalVideoManager: ensures only one video plays at a time
class GlobalVideoManager {
  static final GlobalVideoManager _i = GlobalVideoManager._internal();
  static GlobalVideoManager get instance => _i;
  GlobalVideoManager._internal();

  VideoPlayerController? _ctrl;
  String? _url;

  Future<void> play(String url, VideoPlayerController c) async {
    if (_url != url && _ctrl != null) {
      try {
        await _ctrl!.pause();
      } catch (_) {}
    }
    _url = url;
    _ctrl = c;
    await c.play();
  }

  Future<void> pause() async {
    try {
      await _ctrl?.pause();
    } catch (_) {}
  }

  bool isPlaying(String url) =>
      _url == url && (_ctrl?.value.isPlaying ?? false);
}

class SimpleVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool lazyInit;
  final double? width;
  final double? height;
  final bool enableFullScreen;
  final VoidCallback? onError;
  final String? heroTag;
  final String? thumbnailPath;

  const SimpleVideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.lazyInit = false,
    this.width,
    this.height,
    this.enableFullScreen = true,
    this.onError,
    this.heroTag,
    this.thumbnailPath,
  });

  @override
  State<SimpleVideoPlayerWidget> createState() =>
      _SimpleVideoPlayerWidgetState();

  static Future<void> pauseAllVideos() => GlobalVideoManager.instance.pause();
}

class _SimpleVideoPlayerWidgetState extends State<SimpleVideoPlayerWidget>
    with AutomaticKeepAliveClientMixin {
  final _manager = GlobalVideoManager.instance;

  VideoPlayerController? _c;
  bool _ready = false;
  bool _playing = false;
  bool _buffering = false;
  bool _error = false;
  bool _initializing = false;
  bool _everInitialized = false;

  double _controlsOpacity = 1.0;
  Timer? _controlsTimer;
  String? _generatedThumbnailPath;

  String get _hero => widget.heroTag ?? widget.videoUrl;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!widget.lazyInit || widget.autoPlay) {
      _init(widget.videoUrl, autoStart: widget.autoPlay);
    } else {
      _showControlsTemporarily(force: true);
    }
    _generateThumbnail();
  }

  // ------------------- Generate Thumbnail -------------------
  Future<void> _generateThumbnail() async {
    if (widget.thumbnailPath != null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final thumb = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );
      if (mounted && thumb != null) {
        setState(() => _generatedThumbnailPath = thumb);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant SimpleVideoPlayerWidget old) {
    super.didUpdateWidget(old);
    if (old.videoUrl != widget.videoUrl) {
      _disposeCtrl();
      if (!widget.lazyInit || widget.autoPlay) {
        _init(widget.videoUrl, autoStart: widget.autoPlay);
      } else {
        setState(() {
          _ready = false;
          _error = false;
          _everInitialized = false;
        });
      }
      _generateThumbnail();
    }
  }

  // ------------------- Initialize Video -------------------
  Future<void> _init(String url, {bool autoStart = false}) async {
    if (_initializing) return;
    _initializing = true;
    try {
      late final VideoPlayerController controller;

      final uri = Uri.tryParse(url);
      if (uri != null && (uri.scheme == 'file' || uri.scheme.isEmpty)) {
        final path = uri.scheme == 'file' ? uri.toFilePath() : url;
        controller = VideoPlayerController.file(File(path));
      } else {
        // ✅ Now uses CustomCacheManager.fileCache instead of .instance
        final file = await CustomCacheManager.fileCache.getSingleFile(url);
        controller = VideoPlayerController.file(file);
      }

      _c = controller;
      await controller.initialize();
      if (!mounted) return;

      controller.addListener(_onUpdate);
      setState(() {
        _everInitialized = true;
        _ready = true;
        _buffering = controller.value.isBuffering;
        _error = false;
      });

      if (autoStart) {
        try {
          await _manager.play(widget.videoUrl, controller);
        } catch (_) {
          await _playPause();
        }
      } else {
        _showControlsTemporarily(force: true);
      }
    } catch (_) {
      _errorOut();
    } finally {
      _initializing = false;
    }
  }

  // ------------------- Video Listeners -------------------
  void _onUpdate() {
    if (!mounted || _c == null) return;
    final v = _c!.value;
    final playing = v.isPlaying && _manager.isPlaying(widget.videoUrl);
    final buffering = v.isBuffering;

    if (playing != _playing || buffering != _buffering) {
      setState(() {
        _playing = playing;
        _buffering = buffering;
      });
    }
    if (v.hasError && !_error) _errorOut();
  }

  void _errorOut() {
    if (!mounted) return;
    setState(() {
      _error = true;
      _playing = false;
      _buffering = false;
    });
    widget.onError?.call();
  }

  // ------------------- Play / Pause -------------------
  Future<void> _playPause() async {
    if (_error) {
      await _init(widget.videoUrl, autoStart: true);
      return;
    }
    if (!_ready || _c == null) {
      await _init(widget.videoUrl, autoStart: true);
      return;
    }
    try {
      if (_playing && _manager.isPlaying(widget.videoUrl)) {
        await _c!.pause();
      } else {
        await _manager.play(widget.videoUrl, _c!);
      }
      _showControlsTemporarily();
    } catch (_) {
      _errorOut();
    }
  }

  void _showControlsTemporarily({bool force = false}) {
    _controlsTimer?.cancel();
    setState(() => _controlsOpacity = 1.0);
    if (!force && !_playing) return;
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _controlsOpacity = 0.0);
    });
  }

  void _seek(double seconds) {
    if (!_ready || _c == null) return;
    final max = _c!.value.duration.inSeconds.toDouble();
    final clamped = seconds.clamp(0.0, max);
    _c!.seekTo(Duration(seconds: clamped.toInt()));
  }

  void _enterFull() {
    if (!_ready || _error || !widget.enableFullScreen || _c == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullScreenMediaPage(
          controller: _c!,
          heroTag: _hero,
          autoPlay: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_manager.isPlaying(widget.videoUrl)) {
      _manager.pause();
    }
    _disposeCtrl();
    super.dispose();
  }

  void _disposeCtrl() {
    _controlsTimer?.cancel();
    _c?.removeListener(_onUpdate);
    _c?.dispose();
    _c = null;
    _ready = false;
    _playing = false;
    _buffering = false;
    _error = false;
  }

  // ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    final width = widget.width ?? MediaQuery.of(context).size.width;
    final height = widget.height ?? 200;
    final showLoader = (_buffering || (!_ready && !_error && _initializing));

    return GestureDetector(
      onTap: () async {
        await _playPause();
        _showControlsTemporarily();
      },
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(theme),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (_ready && !_error && _c != null)
              SizedBox.expand(child: VideoPlayer(_c!))
            else if (widget.thumbnailPath != null)
              Positioned.fill(
                child: Image.file(File(widget.thumbnailPath!), fit: BoxFit.cover),
              )
            else if (_generatedThumbnailPath != null)
                Positioned.fill(
                  child: Image.file(File(_generatedThumbnailPath!), fit: BoxFit.cover),
                )
              else
                const ColoredBox(color: Colors.black12),

            if (showLoader)
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),

            IgnorePointer(
              ignoring: _controlsOpacity == 0.0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _controlsOpacity,
                child: Stack(
                  children: [
                    if (widget.enableFullScreen && _ready && _c != null)
                      Positioned(
                        right: 12,
                        bottom: 5,
                        child: GestureDetector(
                          onTap: _enterFull,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.fullscreen,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ),

                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),

                    if (_ready && _c != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 24,
                        child: ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _c!,
                          builder: (_, v, __) {
                            final pos = v.position.inSeconds.toDouble();
                            final max = v.duration.inSeconds
                                .toDouble()
                                .clamp(1.0, double.infinity);

                            String fmt(Duration d) {
                              final m = d.inMinutes.remainder(60)
                                  .toString()
                                  .padLeft(2, '0');
                              final s = d.inSeconds.remainder(60)
                                  .toString()
                                  .padLeft(2, '0');
                              return '$m:$s';
                            }

                            return Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(fmt(v.position),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: pos.clamp(0.0, max),
                                    max: max,
                                    onChanged: _seek,
                                    activeColor: AppTheme.primaryAccent(theme),
                                    inactiveColor: AppTheme.textSecondary(theme),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(fmt(v.duration),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 12)),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (_error)
              const Center(
                child:
                Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              ),
          ],
        ),
      ),
    );
  }
}
