// File: lib/support/contact_support_page.dart

import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/app_theme/section_app_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContactSupportPage extends StatefulWidget {
  const ContactSupportPage({super.key});

  @override
  State<ContactSupportPage> createState() => _ContactSupportPageState();
}

class _ContactSupportPageState extends State<ContactSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _name;
  String? _email;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 🔹 Firestore से fetch करना
      final doc = await _firestore.collection("users").doc(user.uid).get();
      final data = doc.data();

      setState(() {
        _name = data?['name'] ?? user.displayName ?? "Guest User";
        _email = data?['email'] ?? user.email ?? "No email";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _name = user.displayName ?? "Guest User";
        _email = user.email ?? "No email";
        _isLoading = false;
      });
    }
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackBar("You must be logged in to contact support", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      final message = _messageController.text.trim();
      final supportData = {
        "userId": user.uid,
        "name": _name,
        "email": _email,
        "message": message,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      };

      // 🔹 Global collection (Admin view)
      final globalRef = await _firestore.collection("contact_support").add(supportData);

      // 🔹 User sub-collection (User view)
      await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("contact_support")
          .doc(globalRef.id)
          .set(supportData);

      _messageController.clear();

      _showSnackBar("Your support request has been submitted successfully!");
    } catch (e) {
      _showSnackBar("Error submitting request: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? AppTheme.errorColor(Theme.of(context))
            : AppTheme.successColor(Theme.of(context)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(theme),
      appBar: SectionAppBar(
        title: "Contact Support",
        onBack: () => Navigator.of(context).pop(),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryColor(theme),
        ),
      )
          : SafeArea(
        child: Padding(
          padding: AppTheme.mediumPadding,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Name field (readonly)
                TextFormField(
                  initialValue: _name,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Name",
                    filled: true,
                    fillColor: AppTheme.inputFieldBackground(theme),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.mediumRadius,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email field (readonly)
                TextFormField(
                  initialValue: _email,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Email",
                    filled: true,
                    fillColor: AppTheme.inputFieldBackground(theme),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.mediumRadius,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message field
                TextFormField(
                  controller: _messageController,
                  maxLines: 4,
                  validator: (val) =>
                  val == null || val.trim().isEmpty ? "Message cannot be empty" : null,
                  decoration: InputDecoration(
                    labelText: "Your Message",
                    hintText: "Type your issue here...",
                    filled: true,
                    fillColor: AppTheme.inputFieldBackground(theme),
                    border: OutlineInputBorder(
                      borderRadius: AppTheme.mediumRadius,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitSupportRequest,
                    icon: _isSubmitting
                        ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.textOnPrimary(theme),
                      ),
                    )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? "Sending..." : "Send Message"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(theme),
                      foregroundColor: AppTheme.textOnPrimary(theme),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.mediumRadius,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
