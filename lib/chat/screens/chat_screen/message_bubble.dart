// v2.2-message_bubble · 2025-10-26T00:30 IST
// lib/chat/Chat_widgets/message_bubble.dart
//
// Updated MessageBubble:
// - Accepts thumbUrl + mediaUrl (cdn) and prefers thumb for fast preview
// - Uses cached network image fallback when local file missing (requires cached_network_image package)
// - Normalizes progress units (accepts 0..1 or 0..100 defensively)
// - Keeps existing callbacks (onDownloadPressed/onStatusUpdate) - UI still drives download/upload actions
// - Small defensive & accessibility tweaks
//
// NOTE: Add `cached_network_image` to pubspec if not present:
//   cached_network_image: ^3.2.3
//
// Do not change callback signatures here; the repo/UI should call MessageRepository for downloads/uploads.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/chat/utils/timestamp_utils.dart';
import 'package:bargain/chat/Chat_widgets/FullScreenImagePage.dart';
import 'package:bargain/chat/Chat_widgets/video_player_widget.dart';
import 'package:bargain/chat/Chat_widgets/message_time_status_widget.dart';
import 'package:bargain/chat/Chat_widgets/audio_player_widget.dart';
import 'package:bargain/chat/utils/thumbnail_cache.dart';
import 'package:video_player/video_player.dart';

class MessageBubble extends StatefulWidget {
  final bool isMe;
  final String message;
  final String? mediaUrl; // full-size CDN URL
  final String? thumbUrl; // small transform / thumb URL (preferred for previews)
  final String messageType; // text | image | video | audio | file
  final String messageId;
  final String receiverId;
  final int status; // internal status int (-1..3)
  final String conversationId;
  final String? localPath;
  final VoidCallback? onStatusUpdate;
  final VoidCallback onDownloadPressed; // UI triggers repo download/upload
  final double? progress; // accepts 0..1 or 0..100 (normalized internally)
  final String? downloadStatus; // idle/downloading/completed/failed
  final bool? isDownloading;
  final bool videoLazyInit;
  final bool videoAutoPlay;
  final int timestamp; // epoch ms

  // Visual / behavior tweaks
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool enableSelection;
  final bool linkifyText;
  final bool useGradientForSender;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.isMe,
    required this.message,
    this.mediaUrl,
    this.thumbUrl,
    this.messageType = 'text',
    required this.messageId,
    required this.receiverId,
    required this.status,
    required this.conversationId,
    this.localPath,
    this.onStatusUpdate,
    required this.onDownloadPressed,
    this.progress,
    this.downloadStatus = 'idle',
    this.isDownloading = false,
    this.videoLazyInit = true,
    this.videoAutoPlay = false,
    required this.timestamp,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.enableSelection = true,
    this.linkifyText = true,
    this.useGradientForSender = false,
    this.onLongPress,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  static const _padH = 12.0;
  static const _padV = 8.0;
  static const _r = 16.0;
  static const _strokeW = 1.0;

  double get _screenW => MediaQuery.of(context).size.width;
  double get _textMaxW => math.min(_screenW * 0.78, 520);
  double get _mediaW => math.min(_screenW * 0.60, 420);

  late int _currentStatus;
  String? _localPath;
  bool _hasLocal = false;

  bool _stalled = false;
  Timer? _statusDebounce;
  Timer? _downloadTimeout;
  static const _debounce = Duration(milliseconds: 250);
  static const _downloadLimit = Duration(seconds: 60);

  // Thumbnail state (video only)
  String? _thumbPath;
  bool _thumbLoading = false;

  String get _formattedTime => TimestampUtils.formatTime(widget.timestamp);

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.status;
    _localPath = widget.localPath;
    _checkLocalExists();
    _handleDownloadState();
    if (widget.messageType == 'video') {
      _prepareThumbnail();
    }
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localPath != widget.localPath) {
      _localPath = widget.localPath;
      _checkLocalExists();
      if (widget.messageType == 'video') _prepareThumbnail();
    }
    if (oldWidget.status != widget.status) {
      _statusDebounce?.cancel();
      _statusDebounce = Timer(_debounce, () {
        if (mounted) setState(() => _currentStatus = widget.status);
      });
    }
    if (oldWidget.downloadStatus != widget.downloadStatus ||
        oldWidget.isDownloading != widget.isDownloading) {
      _handleDownloadState();
    }
  }

  @override
  void dispose() {
    _statusDebounce?.cancel();
    _downloadTimeout?.cancel();
    super.dispose();
  }

  bool get _isMedia => const {'image', 'video', 'audio'}.contains(widget.messageType);

  String get _normStatus {
    final s = (widget.downloadStatus ?? 'idle').toLowerCase();
    if (s == 'complete') return 'completed';
    if (s == 'error') return 'failed';
    return s;
  }

  // Normalize progress to 0..1 defensively
  double get _normalizedProgress {
    final p = widget.progress ?? 0.0;
    if (p <= 0) return 0.0;
    if (p > 0 && p <= 1.0) return p;
    if (p > 1.0 && p <= 100.0) return (p / 100.0);
    // fallback for strange values
    return (p.clamp(0.0, 100.0) / 100.0);
  }

  Future<void> _checkLocalExists() async {
    final p = _localPath;
    if (widget.isMe && _isMedia && p != null && p.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _hasLocal = true;
        _stalled = false;
      });
      if (widget.messageType == 'video') _prepareThumbnail();
      return;
    }

    if (p == null || p.isEmpty) {
      if (!mounted) return;
      setState(() {
        _hasLocal = false;
        _stalled = false;
      });
      return;
    }
    try {
      final exists = await File(p).exists();
      if (mounted) {
        setState(() {
          _hasLocal = exists;
          if (!exists) _stalled = false;
        });
      }
      if (exists && widget.messageType == 'video') _prepareThumbnail();
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasLocal = false;
          _stalled = false;
        });
      }
    }
  }

  void _handleDownloadState() {
    final s = _normStatus;
    if (s == 'downloading' && (widget.isDownloading ?? false) && !_hasLocal) {
      _stalled = false;
      _downloadTimeout?.cancel();
      _downloadTimeout = Timer(_downloadLimit, () {
        if (mounted && !_hasLocal) setState(() => _stalled = true);
      });
    } else {
      _downloadTimeout?.cancel();
      if (s == 'completed') _stalled = false;
    }
  }

  Future<void> _prepareThumbnail() async {
    if (widget.messageType != 'video') return;
    final p = _localPath;
    if (p == null || p.isEmpty) {
      if (mounted) setState(() => _thumbPath = null);
      return;
    }
    if (!mounted) return;
    setState(() => _thumbLoading = true);
    try {
      final path = await ThumbnailCache.instance.getOrCreate(
        messageId: widget.messageId,
        sourceUrlOrPath: p,
      );
      if (mounted) setState(() => _thumbPath = path);
    } catch (_) {
      if (mounted) setState(() => _thumbPath = null);
    } finally {
      if (mounted) setState(() => _thumbLoading = false);
    }
  }

  void _requestDownload() {
    if (_hasLocal) return;
    widget.onDownloadPressed();
    if (_stalled) setState(() => _stalled = false);
  }

  void _openFullScreen() {
    if (!_hasLocal && (widget.thumbUrl == null && widget.mediaUrl == null)) return;
    // Prefer local path when available
    final useLocal = _hasLocal && _localPath != null && _localPath!.isNotEmpty;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          if (widget.messageType == 'image') {
            return FullScreenMediaPage(
              mediaUrl: useLocal ? _localPath! : (widget.mediaUrl ?? widget.thumbUrl ?? ''),
              isImage: true,
              heroTag: '${widget.messageId}_${widget.messageType}',
            );
          }
          // video
          return FullScreenMediaPage(
            controller: useLocal
                ? VideoPlayerController.file(File(_localPath!))
                : VideoPlayerController.network(widget.mediaUrl ?? ''),
            heroTag: '${widget.messageId}_${widget.messageType}',
            autoPlay: true,
          );
        },
      ),
    );
  }

  String _downloadLabel(double p) {
    final s = _normStatus;
    final percent = (p * 100).toStringAsFixed(0);
    if ((widget.isDownloading ?? false) && s == 'downloading') {
      return p > 0 ? '$percent%' : 'Downloading…';
    }
    if (_stalled) return 'Tap to retry';
    switch (s) {
      case 'failed':
        return 'Retry download';
      case 'completed':
        return 'Downloaded';
      default:
        return 'Tap to download';
    }
  }

  Color _actionCircleColor(ThemeData theme) {
    if (_stalled) return Colors.orange;
    switch (_normStatus) {
      case 'downloading':
        return AppTheme.customTimeTextColor(theme);
      case 'failed':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return AppTheme.primaryAccent(theme);
    }
  }

  IconData _actionCircleIcon() {
    if (_stalled) return Icons.refresh;
    switch (_normStatus) {
      case 'failed':
        return Icons.refresh;
      case 'completed':
        return Icons.check;
      default:
        return Icons.download;
    }
  }

  Widget _timeTicks({Color? overlayBg}) {
    return MessageTimeStatusWidget(
      time: _formattedTime,
      status: _currentStatus,
      isMe: widget.isMe,
    );
  }

  BorderRadius _bubbleRadius(bool isMe) {
    final topLeft = isMe ? _r : (widget.isFirstInGroup ? _r : 6);
    final topRight = isMe ? (widget.isFirstInGroup ? _r : 6) : _r;
    final bottomLeft = isMe ? (widget.isLastInGroup ? _r : 6) : 6;
    final bottomRight = isMe ? 6 : (widget.isLastInGroup ? _r : 6);
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft.toDouble()),
      topRight: Radius.circular(topRight.toDouble()),
      bottomLeft: Radius.circular(bottomLeft.toDouble()),
      bottomRight: Radius.circular(bottomRight.toDouble()),
    );
  }

  Decoration _bubbleDecoration({
    required bool isMe,
    required ThemeData theme,
    required Color stroke,
  }) {
    final baseColor = isMe ? AppTheme.customSenderBubbleColor(theme) : AppTheme.customReceiverBubbleColor(theme);
    if (isMe && widget.useGradientForSender) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [baseColor, baseColor.withOpacity(0.88)],
        ),
        border: Border.all(color: stroke, width: _strokeW),
        borderRadius: _bubbleRadius(isMe),
      );
    }
    return BoxDecoration(
      color: baseColor,
      border: Border.all(color: stroke, width: _strokeW),
      borderRadius: _bubbleRadius(isMe),
    );
  }

  Widget _textBubble() {
    final theme = Theme.of(context);
    final isMe = widget.isMe;
    final stroke = AppTheme.customTimeTextColor(theme).withOpacity(.25);
    final textColor = AppTheme.customMessageTextColor(theme);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: _textMaxW),
      margin: EdgeInsets.only(left: isMe ? 10 : 0, right: isMe ? 0 : 10),
      padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
      decoration: _bubbleDecoration(isMe: isMe, theme: theme, stroke: stroke),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (_) {
              final style = TextStyle(color: textColor, fontSize: 15, height: 1.30);
              if (widget.linkifyText) {
                // If you add linkify, replace with Linkify widget
                return SelectableText(widget.message, style: style);
              }
              if (widget.enableSelection) {
                return SelectableText(widget.message, style: style);
              }
              return Text(widget.message, softWrap: true, overflow: TextOverflow.visible, style: style);
            },
          ),
          const SizedBox(height: 2),
          MessageTimeStatusWidget(time: _formattedTime, status: _currentStatus, isMe: isMe),
        ],
      ),
    );

    return _TailWrapper(isMe: isMe, stroke: stroke, child: bubble);
  }

  Widget _imageBubble() {
    final theme = Theme.of(context);
    final stroke = AppTheme.customTimeTextColor(theme).withOpacity(.25);

    // Local file present -> show file
    if (_hasLocal && _localPath != null) {
      return _localImageCard(theme, stroke);
    }

    // Else try thumbnail (thumbUrl) or mediaUrl via cached network image for fast preview
    final previewUrl = widget.thumbUrl ?? widget.mediaUrl;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return Semantics(
        label: 'Photo, ${_downloadLabel(_normalizedProgress)}',
        child: GestureDetector(
          onTap: _openFullScreen,
          onLongPress: widget.onLongPress,
          child: Hero(
            tag: '${widget.messageId}_${widget.messageType}',
            child: Container(
              width: _mediaW,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: stroke, width: _strokeW)),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: previewUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppTheme.surfaceColor(theme)),
                    errorWidget: (_, __, ___) => _brokenFile(theme),
                  ),
                  Positioned(right: widget.isMe ? 8 : null, left: widget.isMe ? null : 8, bottom: 8, child: _timeTicks(overlayBg: Colors.black54)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // No preview -> show download card
    final bg = widget.isMe ? AppTheme.customSenderBubbleColor(theme) : AppTheme.customReceiverBubbleColor(theme);
    return _mediaDownloadCard(icon: Icons.image, label: 'Photo', bg: bg, stroke: stroke);
  }

  Widget _localImageCard(ThemeData theme, Color stroke) {
    return Semantics(
      label: 'Photo, ${_downloadLabel(1.0)}',
      child: GestureDetector(
        onTap: _openFullScreen,
        onLongPress: widget.onLongPress,
        child: Hero(
          tag: '${widget.messageId}_${widget.messageType}',
          child: Container(
            width: _mediaW,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: stroke, width: _strokeW)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                AspectRatio(aspectRatio: 4 / 3, child: Image.file(File(_localPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _brokenFile(theme))),
                Positioned(right: widget.isMe ? 8 : null, left: widget.isMe ? null : 8, bottom: 8, child: _timeTicks(overlayBg: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _videoBubble() {
    final theme = Theme.of(context);
    final stroke = AppTheme.customTimeTextColor(theme).withOpacity(.25);

    if (_hasLocal && (_localPath?.isNotEmpty ?? false)) {
      return Semantics(
        label: 'Video, ${_downloadLabel(1.0)}',
        child: Container(
          width: _mediaW,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: stroke, width: _strokeW)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: SimpleVideoPlayerWidget(
                  videoUrl: _localPath!,
                  autoPlay: widget.videoAutoPlay,
                  lazyInit: widget.videoLazyInit,
                  heroTag: '${widget.messageId}_${widget.messageType}',
                  thumbnailPath: _thumbPath,
                ),
              ),
              Positioned(right: widget.isMe ? 8 : null, left: widget.isMe ? null : 8, bottom: 8, child: _timeTicks(overlayBg: Colors.black54)),
              if (_thumbLoading)
                const Positioned(top: 8, right: 8, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
            ],
          ),
        ),
      );
    }

    // network preview via thumbUrl or mediaUrl
    final previewUrl = widget.thumbUrl ?? widget.mediaUrl;
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return Semantics(
        label: 'Video, ${_downloadLabel(_normalizedProgress)}',
        child: GestureDetector(
          onTap: _requestDownload,
          child: Container(
            width: _mediaW,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: stroke, width: _strokeW)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                CachedNetworkImage(imageUrl: previewUrl, fit: BoxFit.cover, placeholder: (_, __) => Container(color: AppTheme.surfaceColor(theme)), errorWidget: (_, __, ___) => _mediaDownloadCard(icon: Icons.videocam, label: 'Video', bg: AppTheme.surfaceColor(theme), stroke: stroke)),
                Positioned(right: widget.isMe ? 8 : null, left: widget.isMe ? null : 8, bottom: 8, child: _timeTicks(overlayBg: Colors.black54)),
                if (_thumbLoading) const Positioned(top: 8, right: 8, child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
              ],
            ),
          ),
        ),
      );
    }

    final bg = widget.isMe ? AppTheme.customSenderBubbleColor(theme) : AppTheme.customReceiverBubbleColor(theme);
    return _mediaDownloadCard(icon: Icons.videocam, label: 'Video', bg: bg, stroke: stroke);
  }

  Widget _audioBubble() {
    final theme = Theme.of(context);
    final bg = widget.isMe ? AppTheme.customSenderBubbleColor(theme) : AppTheme.customReceiverBubbleColor(theme);
    final stroke = AppTheme.customTimeTextColor(theme).withOpacity(.25);

    final container = (Widget child) => Container(
      width: _mediaW,
      padding: const EdgeInsets.symmetric(horizontal: _padH, vertical: _padV),
      decoration: BoxDecoration(color: bg, border: Border.all(color: stroke, width: _strokeW), borderRadius: BorderRadius.circular(14)),
      child: child,
    );

    if (_hasLocal && (_localPath?.isNotEmpty ?? false)) {
      return Semantics(
        label: 'Voice message, Downloaded',
        child: container(
          AudioPlayerWidget(
            audioUrl: _localPath!,
            isMe: widget.isMe,
            width: _mediaW - (_padH * 2),
            time: _formattedTime,
            status: _currentStatus,
            showWaveform: true,
            autoPlay: false,
            onPlayingStarted: widget.onStatusUpdate ?? () {},
            onPlayingFinished: widget.onStatusUpdate ?? () {},
          ),
        ),
      );
    }

    final p = _normalizedProgress;
    final label = _downloadLabel(p);
    final isDownloading = (widget.isDownloading ?? false) && _normStatus == 'downloading';

    return container(
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _requestDownload,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: _actionCircleColor(theme), shape: BoxShape.circle),
              child: isDownloading
                  ? Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(value: p > 0 ? p : null, strokeWidth: 3, valueColor: const AlwaysStoppedAnimation(Colors.white)),
              )
                  : Icon(_actionCircleIcon(), color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.mic, size: 12, color: AppTheme.customMessageTextColor(theme)),
                const SizedBox(width: 4),
                const Text('Voice message', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
              const SizedBox(height: 1),
              Text(label, style: TextStyle(color: AppTheme.customTimeTextColor(theme), fontSize: 10)),
            ]),
          ),
          const SizedBox(width: 6),
          _timeTicks(),
        ],
      ),
    );
  }

  Widget _mediaDownloadCard({required IconData icon, required String label, required Color bg, required Color stroke}) {
    final p = _normalizedProgress;
    final isDownloading = (widget.isDownloading ?? false) && _normStatus == 'downloading';
    final text = _downloadLabel(p);

    return Semantics(
      label: '$label, $text',
      button: true,
      child: Container(
        width: _mediaW,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: stroke, width: _strokeW)),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            GestureDetector(
              onTap: _requestDownload,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: _actionCircleColor(Theme.of(context)), shape: BoxShape.circle),
                child: isDownloading
                    ? Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(value: p > 0 ? p : null, strokeWidth: 3, valueColor: const AlwaysStoppedAnimation(Colors.white)),
                )
                    : Icon(icon, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 6),
            Text(text == 'Tap to download' ? 'Tap to download $label' : text, style: TextStyle(color: AppTheme.customMessageTextColor(Theme.of(context)), fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _brokenFile(ThemeData theme) {
    return Container(
      color: AppTheme.surfaceColor(theme),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.broken_image, color: AppTheme.textSecondary(theme)),
          const SizedBox(height: 6),
          Text('File not found', style: TextStyle(color: AppTheme.textSecondary(theme), fontSize: 12)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final child = !_isMedia
        ? _textBubble()
        : (widget.messageType == 'image' ? _imageBubble() : (widget.messageType == 'video' ? _videoBubble() : _audioBubble()));

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: widget.isMe ? MainAxisAlignment.end : MainAxisAlignment.start, children: [child]),
    );

    return GestureDetector(behavior: HitTestBehavior.translucent, onLongPress: widget.onLongPress, child: row);
  }
}

// Tail painter wrapper keeps painter + hitbox clean and RTL aware
class _TailWrapper extends StatelessWidget {
  final bool isMe;
  final double inset;
  final Color stroke;
  final Widget child;

  const _TailWrapper({required this.isMe, this.inset = 0, required this.stroke, required this.child});

  @override
  Widget build(BuildContext context) {
    final dir = Directionality.of(context);
    final effectiveIsMe = dir == TextDirection.rtl ? !isMe : isMe;
    final theme = Theme.of(context);
    final bg = effectiveIsMe ? AppTheme.customSenderBubbleColor(theme) : AppTheme.customReceiverBubbleColor(theme);

    return CustomPaint(painter: _TailPainter(isMe: effectiveIsMe, color: bg, borderColor: stroke), child: child);
  }
}

class _TailPainter extends CustomPainter {
  final bool isMe;
  final Color color;
  final Color borderColor;

  _TailPainter({required this.isMe, required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    const tailWidth = 8.0;
    const tailHeight = 10.0;

    final path = Path();
    if (isMe) {
      path.moveTo(size.width - 6, size.height - 6);
      path.lineTo(size.width - 6, size.height + tailHeight - 6);
      path.quadraticBezierTo(size.width - 6 - tailWidth * 0.4, size.height + tailHeight - 6, size.width - 6 - tailWidth, size.height - 2);
    } else {
      path.moveTo(6, size.height - 6);
      path.lineTo(6, size.height + tailHeight - 6);
      path.quadraticBezierTo(6 + tailWidth * 0.4, size.height + tailHeight - 6, 6 + tailWidth, size.height - 2);
    }

    final paintFill = Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true;
    final paintStroke = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = _MessageBubbleState._strokeW..isAntiAlias = true;

    canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);
  }

  @override
  bool shouldRepaint(covariant _TailPainter old) {
    return old.isMe != isMe || old.color != color || old.borderColor != borderColor;
  }
}
