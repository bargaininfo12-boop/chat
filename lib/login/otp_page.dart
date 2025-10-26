// File: lib/login/otp_page.dart
// v3.3.0 — FCM-safe OTP verification integrated with FirebaseAuthService

import 'dart:async';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/Services/user_service.dart';
import 'package:bargain/account_setting/UserSetupPage.dart';
import 'package:bargain/homesceen/home_page.dart';
import 'package:bargain/app_theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  OtpPageState createState() => OtpPageState();
}

class OtpPageState extends State<OtpPage> with TickerProviderStateMixin {
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService.instance;
  final UserService _userService = UserService();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _pinPutFocusNode = FocusNode();

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // State
  String? _otpCode;
  bool _isLoading = false;
  bool _isResending = false;
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenForOTP();
    _startCountdown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _pinPutFocusNode.dispose();
    _fadeController.dispose();
    _timer?.cancel();
    SmsAutoFill().unregisterListener();
    super.dispose();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: AppTheme.longDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  void _listenForOTP() async {
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        final permission = await Permission.sms.request();
        if (permission.isGranted) {
          await SmsAutoFill().listenForCode();
        }
      }
    } catch (e) {
      debugPrint('⚠️ SMS permission error: $e');
    }
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // ============================================================
  // 🔐 OTP Sign-in using FirebaseAuthService (with FCM token)
  // ============================================================
  Future<void> _signInWithOTP() async {
    if (_otpCode == null || _otpCode!.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpCode!,
      );

      // ✅ Use our unified FirebaseAuthService (includes FCM handling)
      final userCredential =
      await _firebaseAuthService.signInWithCredential(credential);
      final user = userCredential.user;

      if (!mounted || user == null) return;

      HapticFeedback.heavyImpact();
      _firebaseAuthService.startTokenRefreshListener(); // ensure auto token sync

      // 🧠 Initialize user profile (Firestore data + deletion check)
      final status = await _userService.initializeUser(user);
      if (!mounted) return;

      switch (status) {
        case UserProfileStatus.complete:
          debugPrint('✅ Profile complete - navigating to HomePage');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => HomePage(user: user)),
                (_) => false,
          );
          break;

        case UserProfileStatus.incomplete:
        case UserProfileStatus.locationNeeded:
          debugPrint('⚠️ Profile incomplete - navigating to UserSetupPage');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => UserSetupPage(user: user)),
                (_) => false,
          );
          break;
      }
    } on FirebaseAuthException catch (e) {
      _showError(_getFirebaseErrorMessage(e.code));
    } catch (e) {
      _showError('Verification failed. Please try again.');
      debugPrint('❌ OTP verification error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // 🔁 Resend OTP
  // ============================================================
  Future<void> _resendOTP() async {
    if (_isResending) return;

    setState(() => _isResending = true);
    HapticFeedback.lightImpact();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        verificationCompleted: (_) {},
        verificationFailed: (e) =>
            _showError('Failed to resend OTP: ${e.message}'),
        codeSent: (verificationId, _) {
          setState(() {
            _countdown = 60;
            _otpController.clear();
            _otpCode = null;
          });
          _startCountdown();
          _showSuccess('OTP resent successfully!');
        },
        codeAutoRetrievalTimeout: (_) {},
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _showError('Failed to resend OTP. Please try again.');
      debugPrint('❌ OTP resend error: $e');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  // ============================================================
  // 🧩 UI Helpers
  // ============================================================
  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'session-expired':
        return 'OTP has expired. Please request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'Verification failed. Please try again.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor(Theme.of(context)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor(Theme.of(context)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
      ),
    );
  }

  // ============================================================
  // 🧱 UI Builders
  // ============================================================
  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor(Theme.of(context)),
            borderRadius: AppTheme.largeRadius,
            boxShadow: AppTheme.mediumShadow(Theme.of(context)),
          ),
          child: Icon(Icons.security,
              size: 40, color: AppTheme.textOnPrimary(Theme.of(context))),
        ),
        const SizedBox(height: 32),
        Text(
          "Enter Verification Code",
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: AppTheme.textPrimary(Theme.of(context)),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary(Theme.of(context)),
            ),
            children: [
              const TextSpan(text: "We've sent a 6-digit code to\n"),
              TextSpan(
                text: widget.phoneNumber,
                style: TextStyle(
                  color: AppTheme.primaryColor(Theme.of(context)),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOTPInput() {
    return Column(
      children: [
        Pinput(
          length: 6,
          focusNode: _pinPutFocusNode,
          controller: _otpController,
          autofocus: true,
          defaultPinTheme: _pinTheme(AppTheme.borderColor(Theme.of(context))),
          focusedPinTheme:
          _pinTheme(AppTheme.primaryColor(Theme.of(context)), width: 2),
          submittedPinTheme:
          _pinTheme(AppTheme.successColor(Theme.of(context)), width: 2),
          pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
          showCursor: true,
          onCompleted: (pin) {
            setState(() => _otpCode = pin);
            _signInWithOTP();
          },
          onChanged: (pin) => setState(() => _otpCode = pin.length == 6 ? pin : null),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Didn't receive the code? ",
                style: TextStyle(
                    color: AppTheme.textSecondary(Theme.of(context)),
                    fontSize: 14)),
            if (_countdown > 0)
              Text("Resend in ${_countdown}s",
                  style: TextStyle(
                      color: AppTheme.textSecondary(Theme.of(context)),
                      fontSize: 14,
                      fontWeight: FontWeight.w500))
            else
              GestureDetector(
                onTap: _resendOTP,
                child: Text(
                  _isResending ? "Sending..." : "Resend",
                  style: TextStyle(
                      color: AppTheme.primaryColor(Theme.of(context)),
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ],
    );
  }

  PinTheme _pinTheme(Color color, {double width = 1}) => PinTheme(
    width: 50,
    height: 56,
    textStyle: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppTheme.textPrimary(Theme.of(context)),
    ),
    decoration: BoxDecoration(
      color: AppTheme.inputFieldBackground(Theme.of(context)),
      border: Border.all(color: color, width: width),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  Widget _buildVerifyButton() => SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: (_otpCode != null && !_isLoading) ? _signInWithOTP : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor(Theme.of(context)),
        foregroundColor: AppTheme.textOnPrimary(Theme.of(context)),
        elevation: _otpCode != null ? 2 : 0,
        shape:
        RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
      ),
      child: _isLoading
          ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2))
          : const Text(
        "Verify & Continue",
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(Theme.of(context)),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppTheme.iconColor(Theme.of(context))),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verification',
          style: TextStyle(
              color: AppTheme.textPrimary(Theme.of(context)),
              fontWeight: FontWeight.w600),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: AppTheme.largePadding,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildHeader(),
                        const SizedBox(height: 48),
                        _buildOTPInput(),
                      ],
                    ),
                  ),
                ),
                _buildVerifyButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
