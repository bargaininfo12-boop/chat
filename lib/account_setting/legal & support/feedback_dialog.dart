// File: lib/support/feedback_dialog.dart

import 'package:bargain/app_theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({super.key});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _setRating(int value) {
    setState(() {
      _rating = value;
    });
  }

  Future<void> _submitFeedback() async {
    if (_rating == 0) {
      _showSnackBar("Please select a rating before submitting", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    HapticFeedback.lightImpact();

    try {
      final user = _auth.currentUser;
      final feedbackData = {
        "userId": user?.uid,
        "rating": _rating,
        "feedback": _feedbackController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      };

      // Save feedback in Firestore
      await _firestore.collection("feedbacks").add(feedbackData);

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        _showSnackBar("Thank you for your feedback!");
      }
    } catch (e) {
      _showSnackBar("Error submitting feedback: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white),
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
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppTheme.largeRadius),
      backgroundColor: AppTheme.cardColor(theme),
      child: Padding(
        padding: AppTheme.largePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Send Feedback",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(theme),
                )),

            const SizedBox(height: 16),

            // ⭐ Rating Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => _setRating(index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryColor(theme),
                    size: 32,
                  ),
                );
              }),
            ),

            const SizedBox(height: 12),

            // Feedback Text Field
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Tell us about your experience...",
                filled: true,
                fillColor: AppTheme.inputFieldBackground(theme),
                border: OutlineInputBorder(
                  borderRadius: AppTheme.mediumRadius,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(theme),
                      foregroundColor: AppTheme.textOnPrimary(theme),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppTheme.mediumRadius),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text("Submit"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
