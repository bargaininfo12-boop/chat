// 🚀 SLIM & SAFE: AudioPlayerWidget (compact UI + lifecycle hardening)
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bargain/app_theme/app_theme.dart';

/// Public interface for owner reference
abstract class AudioOwner {
  Future<void> stopAudio({bool silent = false});
}

/// Single shared player to avoid overlapping audio.
class GlobalAudioManager {
  static final GlobalAudioManager _i = GlobalAudioManager._internal();
  static GlobalAudioManager get instance => _i;
  GlobalAudioManager._internal();

  AudioPlayer? _player;
  String? _currentUrl;
  AudioOwner? _owner;

  AudioPlayer get player {
    _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    return _player!;
  }

  bool isCurrent(String url) => _currentUrl == url;

  Future<void> play(String url, AudioOwner owner) async {
    // handover to new owner
    if (_owner != null && _owner != owner) {
      await _owner!.stopAudio(silent: true);
    }
    _owner = owner;
    _currentUrl = url;

    final isLocal = !url.startsWith('http');
    if (isLocal) {
      final f = File(url);
      if (!await f.exists()) throw Exception('file-missing');
      await player.play(DeviceFileSource(url));
    } else {
      await player.play(UrlSource(url));
    }
  }

  Future<void> stopCurrent() async {
    if (_owner != null) {
      await _owner!.stopAudio(silent: true);
    }
    _owner = null;
    _currentUrl = null;
  }

  void clearOwner(AudioOwner s) {
    if (_owner == s) {
      _owner = null;
      _currentUrl = null;
    }
  }

  Future<void> dispose() async {
    await _player?.dispose();
    _player = null;
    _owner = null;
    _currentUrl = null;
  }
}

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isMe;
  final double? width;
  final String? time;
  final int? status;
  final VoidCallback? onPlayingStarted;
  final VoidCallback? onPlayingFinished;
  final bool showWaveform;
  final bool autoPlay;

  const AudioPlayerWidget({
    super.key,
    required this.audioUrl,
    required this.isMe,
    this.width,
    this.time,
    this.status,
    this.onPlayingStarted,
    this.onPlayingFinished,
    this.showWaveform = true,
    this.autoPlay = false,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin
    implements AudioOwner {
  final GlobalAudioManager _mgr = GlobalAudioManager.instance;
  late final AudioPlayer _player;

  // state
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _err = '';
  Duration _dur = Duration.zero;
  Duration _pos = Duration.zero;

  // slim animation for play→pause icon
  late final AnimationController _iconCtl =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 160));
  late final Animation<double> _iconAnim =
  CurvedAnimation(parent: _iconCtl, curve: Curves.easeInOut);

  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _durSub;
  StreamSubscription<Duration>? _posSub;

  late final List<double> _wf =
  List.generate(6, (_) => 0.35 + math.Random().nextDouble() * 0.4);

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _player = _mgr.player;
    _attachListeners();

    // optional auto play (safe delay)
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _toggle();
      });
    }
  }

  void _attachListeners() {
    _stateSub = _player.onPlayerStateChanged.listen((state) {
      if (!mounted || _disposed) return;
      final isOwner = _mgr.isCurrent(widget.audioUrl);

      // reflect only if this widget owns playback
      if (!isOwner) {
        if (_isPlaying) setState(() => _isPlaying = false);
        _iconCtl.reverse();
        return;
      }

      if (state == PlayerState.playing) {
        setState(() {
          _isPlaying = true;
          _isLoading = false;
          _hasError = false;
        });
        _iconCtl.forward();
        widget.onPlayingStarted?.call();
      } else if (state == PlayerState.completed) {
        setState(() {
          _isPlaying = false;
          _pos = Duration.zero;
        });
        _iconCtl.reverse();
        widget.onPlayingFinished?.call();
      } else if (state == PlayerState.paused || state == PlayerState.stopped) {
        setState(() => _isPlaying = false);
        _iconCtl.reverse();
      }
    });

    _durSub = _player.onDurationChanged.listen((d) {
      if (!mounted || _disposed || !_mgr.isCurrent(widget.audioUrl)) return;
      setState(() {
        _dur = d;
        _isLoading = false;
      });
    });

    _posSub = _player.onPositionChanged.listen((p) {
      if (!mounted || _disposed || !_mgr.isCurrent(widget.audioUrl)) return;
      setState(() => _pos = p);
    });
  }

  Future<void> _toggle() async {
    if (!mounted || _disposed) return;
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      if (_isPlaying && _mgr.isCurrent(widget.audioUrl)) {
        await _player.pause();
      } else {
        await _mgr.play(widget.audioUrl, this);
      }
      HapticFeedback.selectionClick();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _err = (e.toString().contains('file-missing'))
            ? 'Audio file not found'
            : 'Failed to play audio';
      });
    }
  }

  @override
  Future<void> stopAudio({bool silent = false}) async {
    // called by manager during handover/pop
    if (_disposed) return;
    try {
      await _player.stop();
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _isPlaying = false;
          _pos = Duration.zero;
        });
      } else {
        _isPlaying = false;
        _pos = Duration.zero;
      }
      _iconCtl.reverse();
    } catch (_) {}
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _statusIcon() {
    if (!widget.isMe || widget.status == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    late IconData icon;
    late Color color;
    switch (widget.status!) {
      case -1:
        icon = Icons.error_outline;
        color = AppTheme.customStatusIconFailed(theme);
        break;
      case 0:
      case 1:
        icon = Icons.done;
        color = AppTheme.customStatusIconSent(theme);
        break;
      case 2:
        icon = Icons.done_all;
        color = AppTheme.customStatusIconDelivered(theme);
        break;
      case 3:
        icon = Icons.done_all;
        color = AppTheme.customStatusIconRead(theme);
        break;
      default:
        icon = Icons.done;
        color = AppTheme.customStatusIconSent(theme);
    }
    return Icon(icon, size: 16, color: color);
  }

  @override
  void dispose() {
    _disposed = true;
    _stateSub?.cancel();
    _durSub?.cancel();
    _posSub?.cancel();
    _iconCtl.dispose();
    _mgr.clearOwner(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_disposed) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final accent = AppTheme.primaryAccent(theme);

    return SizedBox(
      width: widget.width ?? 152,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // play button (tiny, solid)
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _hasError ? Colors.red : accent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _isLoading
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: _iconAnim,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // skinny waveform/progress + time + status
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // waveform or thin progress
                SizedBox(
                  height: 14,
                  child: widget.showWaveform
                      ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: _wf.asMap().entries.map((e) {
                            final progress = _dur.inMilliseconds == 0
                                ? 0.0
                                : (_pos.inMilliseconds /
                                _dur.inMilliseconds)
                                .clamp(0.0, 1.0);
                            final active =
                                (e.key / _wf.length) <= progress;
                            return Container(
                              width: 2,
                              height: (e.value * 12).clamp(3.0, 12.0),
                              decoration: BoxDecoration(
                                color: active
                                    ? accent
                                    : accent.withOpacity(0.28),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          height: 3,
                          color: accent.withOpacity(0.18),
                        ),
                        FractionallySizedBox(
                          widthFactor: _dur.inMilliseconds == 0
                              ? 0
                              : (_pos.inMilliseconds /
                              _dur.inMilliseconds)
                              .clamp(0.0, 1.0),
                          alignment: Alignment.centerLeft,
                          child: Container(height: 3, color: accent),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // time + sent/delivered/read
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _fmt(_pos),
                      style: TextStyle(
                        color: AppTheme.customMessageTextColor(theme),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.time != null)
                          Text(
                            widget.time!,
                            style: TextStyle(
                              color: AppTheme.customTimeTextColor(theme),
                              fontSize: 11,
                              height: 1,
                            ),
                          ),
                        const SizedBox(width: 4),
                        _statusIcon(),
                      ],
                    ),
                  ],
                ),

                if (_hasError) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 12, color: Colors.red),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _err.isEmpty ? 'Playback error' : _err,
                          style: const TextStyle(
                              color: Colors.red, fontSize: 10, height: 1),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (!mounted) return;
                          setState(() {
                            _hasError = false;
                            _err = '';
                          });
                          _toggle();
                        },
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
