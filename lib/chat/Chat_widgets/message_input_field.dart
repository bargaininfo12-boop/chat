import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

typedef OnSendText = Future<void> Function(String text);
typedef OnPickMedia = Future<void> Function(File file, String mime);

class MessageInputField extends StatefulWidget {
  final OnSendText onSendText;
  final OnPickMedia onPickMedia;
  final bool enableAttachments;
  final String hintText;

  const MessageInputField({
    Key? key,
    required this.onSendText,
    required this.onPickMedia,
    this.enableAttachments = true,
    this.hintText = 'Type a message',
  }) : super(key: key);

  @override
  State<MessageInputField> createState() => _MessageInputFieldState();
}

class _MessageInputFieldState extends State<MessageInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;
  bool _showAttachmentSheet = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await widget.onSendText(text);
      _controller.clear();
      _focusNode.requestFocus();
    } catch (e) {
      // show simple error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Send failed')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _onAttachPressed() async {
    // show bottom sheet with options
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo from gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take photo'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record video'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Video from gallery'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickImage(
        source: source,
        maxWidth: 3840,
        maxHeight: 3840,
        imageQuality: 85, // slight client compression
      );
      if (xfile == null) return;
      final file = File(xfile.path);
      final mime = lookupMimeType(file.path) ?? 'image/jpeg';
      await widget.onPickMedia(file, mime);
    } catch (e) {
      _showPickerError(e);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? xfile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (xfile == null) return;
      final file = File(xfile.path);
      final mime = lookupMimeType(file.path) ?? 'video/mp4';
      await widget.onPickMedia(file, mime);
    } catch (e) {
      _showPickerError(e);
    }
  }

  void _showPickerError(Object e) {
    // keep UX friendly and short
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot pick file: ${e.toString()}')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          // Attachment button
          if (widget.enableAttachments)
            IconButton(
              onPressed: _onAttachPressed,
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Attach',
            ),
          // Text field
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40, maxHeight: 160),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 2, offset: const Offset(0, 1)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        maxLines: null,
                        minLines: 1,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: widget.hintText,
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) async {
                          // do not send on enter, let send button handle it
                        },
                      ),
                    ),
                    // Send button
                    Padding(
                      padding: const EdgeInsets.only(left: 6.0),
                      child: _isSending
                          ? SizedBox(
                        width: 36,
                        height: 36,
                        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                      )
                          : IconButton(
                        onPressed: () => _handleSend(),
                        icon: const Icon(Icons.send),
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
