// 🎤 FIXED & OPTIMIZED: WhatsApp Style Voice Recorder
// Safe init, theme-aware, no ScaffoldMessenger crash

import 'dart:async';
import 'dart:io';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SimpleVoiceRecorder extends StatefulWidget {
  final String receiverId;
  final void Function(String audioPath)? onRecordingCompleted;
  final VoidCallback? onRecordingCanceled;

  const SimpleVoiceRecorder({
    super.key,
    required this.receiverId,
    this.onRecordingCompleted,
    this.onRecordingCanceled,
  });

  @override
  State<SimpleVoiceRecorder> createState() => _SimpleVoiceRecorderState();
}

class _SimpleVoiceRecorderState extends State<SimpleVoiceRecorder>
    with SingleTickerProviderStateMixin {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _isRecorderInitialized = false;
  bool _isProcessing = false;
  String? _filePath;
  Timer? _timer;
  Duration _recordingDuration = Duration.zero;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _initRecorder();
  }

  void _initAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initRecorder() async {
    try {
      await _recorder.openRecorder();

      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint("❌ Microphone permission denied");
        return;
      }

      if (mounted) setState(() => _isRecorderInitialized = true);
      debugPrint("✅ VoiceRecorder initialized");
    } catch (e) {
      debugPrint("❌ Recorder init error: $e");
      // 🚫 Don't call _showError here (initState safe issue)
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecorderInitialized) {
      _showError("Recorder not ready");
      return;
    }
    _isRecording ? await _stopRecording() : await _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      HapticFeedback.mediumImpact();

      final dir = await getApplicationDocumentsDirectory();
      _filePath =
      '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder.startRecorder(toFile: _filePath, codec: Codec.aacADTS);

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = Duration.zero;
        });
      }

      _animationController.repeat(reverse: true);

      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted && _isRecording) {
          setState(() => _recordingDuration += const Duration(seconds: 1));

          if (_recordingDuration.inMinutes >= 2) {
            _stopRecording();
          }
        }
      });

      debugPrint("🎙️ Recording started at $_filePath");
    } catch (e) {
      debugPrint("❌ Failed to start recording: $e");
      _showError("Recording failed");
    }
  }

  Future<void> _stopRecording() async {
    try {
      HapticFeedback.lightImpact();
      await _recorder.stopRecorder();

      _timer?.cancel();
      _animationController.stop();
      _animationController.reset();

      if (mounted) setState(() => _isRecording = false);

      if (_recordingDuration.inSeconds < 1) {
        _showError("Recording too short");
        widget.onRecordingCanceled?.call();
        await _deleteFile();
        return;
      }

      if (_filePath != null) {
        await _processRecording();
      }
    } catch (e) {
      debugPrint("❌ Stop recording error: $e");
      _showError("Failed to stop recording");
      widget.onRecordingCanceled?.call();
    }
  }

  Future<void> _processRecording() async {
    try {
      if (mounted) setState(() => _isProcessing = true);

      final file = File(_filePath!);
      if (await file.exists()) {
        widget.onRecordingCompleted?.call(_filePath!);
        debugPrint("✅ Recording passed to callback");
      } else {
        throw Exception("Audio file missing");
      }
    } catch (e) {
      debugPrint("❌ Processing error: $e");
      _showError("Processing failed");
      widget.onRecordingCanceled?.call();
      await _deleteFile();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deleteFile() async {
    try {
      if (_filePath != null) {
        final file = File(_filePath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint("🗑️ Deleted temp file");
        }
      }
    } catch (e) {
      debugPrint("❌ File delete error: $e");
    }
    _filePath = null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  void dispose() {
    debugPrint("🧹 VoiceRecorder disposed");
    _timer?.cancel();
    _animationController.dispose();
    if (_isRecording) _recorder.stopRecorder();
    _recorder.closeRecorder();
    if (_filePath != null && !_isProcessing) _deleteFile();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isProcessing) return _buildProcessingButton(theme);
    if (_isRecording) return _buildRecordingButton(theme);
    return _buildIdleButton(theme);
  }

  Widget _buildProcessingButton(ThemeData theme) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryAccent(theme).withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppTheme.primaryAccent(theme)),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingButton(ThemeData theme) {
    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.stop, color: Colors.white, size: 18),
                  if (_recordingDuration.inSeconds > 0)
                    Positioned(
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatDuration(_recordingDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIdleButton(ThemeData theme) {
    return Tooltip(
      message: 'Tap to record voice message',
      child: GestureDetector(
        onTap: _isRecorderInitialized ? _toggleRecording : null,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _isRecorderInitialized
                ? AppTheme.primaryAccent(theme)
                : AppTheme.primaryAccent(theme).withOpacity(0.5),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowColor(theme).withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.mic,
            color: _isRecorderInitialized ? Colors.white : Colors.white70,
            size: 18,
          ),
        ),
      ),
    );
  }
}
