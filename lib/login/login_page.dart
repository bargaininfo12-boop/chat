import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:bargain/app_theme/app_theme.dart';
import 'package:bargain/Database/Firebase_all/app_auth_provider.dart';
import 'package:bargain/Database/Firebase_all/firebase_auth.dart';
import 'package:bargain/services/user_service.dart';
import 'package:bargain/account_setting/UserSetupPage.dart';
import 'package:bargain/homesceen/home_page.dart';
import 'package:bargain/login/otp_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService.instance;
  final UserService _userService = UserService();

  String? _selectedCountryCode = '+91';
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: AppTheme.longDuration, vsync: this);
    _slideController = AnimationController(duration: AppTheme.mediumDuration, vsync: this);

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhoneNumber(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      await _firebaseAuthService.auth.verifyPhoneNumber(
        phoneNumber: '$_selectedCountryCode${_phoneController.text}',
        verificationCompleted: (credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          _showSnackBar('Verification failed: ${e.message}');
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpPage(
                verificationId: verificationId,
                phoneNumber: '$_selectedCountryCode${_phoneController.text}',
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _signInWithCredential(AuthCredential credential) async {
    if (!mounted) return;
    try {
      final userCredential = await _firebaseAuthService.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) return;

      HapticFeedback.heavyImpact();
      context.read<AppAuthProvider>().setUserId(user.uid);

      final profileStatus = await _userService.initializeUser(user);
      final current = _userService.currentUser;

      if (current?.deletionPending == true &&
          current?.deletionScheduledFor != null &&
          DateTime.now().isAfter(current!.deletionScheduledFor!)) {
        await _firebaseAuthService.auth.signOut();
        _showSnackBar('Your account was permanently deleted after the 30-day grace period.');
        return;
      }

      if (profileStatus == UserProfileStatus.complete) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomePage(user: user)),
              (_) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserSetupPage(user: user)),
        );
      }
    } catch (e) {
      _showSnackBar('Sign-in failed: $e');
    }
  }

  Future<void> _googleSignInMethod() async {
    setState(() => _isGoogleLoading = true);
    HapticFeedback.lightImpact();

    try {
      final userCredential = await _firebaseAuthService.signInWithGoogle();
      final user = userCredential?.user;
      if (user == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      HapticFeedback.heavyImpact();
      context.read<AppAuthProvider>().setUserId(user.uid);

      final profileStatus = await _userService.initializeUser(user);
      final current = _userService.currentUser;

      if (current?.deletionPending == true &&
          current?.deletionScheduledFor != null &&
          DateTime.now().isAfter(current!.deletionScheduledFor!)) {
        await _firebaseAuthService.auth.signOut();
        _showSnackBar('Your account was permanently deleted after the 30-day grace period.');
        return;
      }

      if (profileStatus == UserProfileStatus.complete) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomePage(user: user)),
              (_) => false,
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => UserSetupPage(user: user)),
        );
      }
    } catch (e) {
      _showSnackBar('Google Sign-in failed: $e');
    } finally {
      setState(() => _isGoogleLoading = false);
    }
  }

  void _showSnackBar(String msg) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.errorColor(theme),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
        margin: AppTheme.mediumPadding,
      ),
    );
  }

  Widget _buildPhoneInput(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldBackground(theme),
        borderRadius: AppTheme.mediumRadius,
        border: Border.all(color: AppTheme.borderColor(theme)),
      ),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              onChanged: (v) => setState(() => _selectedCountryCode = v),
              items: const [
                {'code': '+91', 'flag': '🇮🇳'},
                {'code': '+1', 'flag': '🇺🇸'},
                {'code': '+44', 'flag': '🇬🇧'},
              ].map((e) {
                return DropdownMenuItem(
                  value: e['code'],
                  child: Text('${e['flag']} ${e['code']}'),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'Enter phone number',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              validator: (v) => v == null || v.length != 10 ? 'Enter valid number' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton({
    required String text,
    required Widget icon,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surfaceColor(theme),
              shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
            ),
          child: isLoading
              ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  color: AppTheme.textPrimary(theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildGradientBackground() => Container(
    decoration: BoxDecoration(
      gradient: AppTheme.backgroundGradient(Theme.of(context)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          _buildGradientBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: AppTheme.largePadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor(theme),
                            borderRadius: AppTheme.largeRadius,
                            boxShadow: AppTheme.mediumShadow(theme),
                          ),
                          child: Icon(Icons.store,
                              color: AppTheme.textOnPrimary(theme), size: 40),
                        ),
                        const SizedBox(height: 40),
                        Text("Welcome to",
                            style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.textSecondary(theme))),
                        Text("Bargain",
                            style: theme.textTheme.headlineLarge?.copyWith(
                                color: AppTheme.textPrimary(theme),
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 50),
                        _buildLoginButton(
                          text: "Continue with Phone",
                          icon: const Icon(Icons.phone_android),
                          onPressed: () => _showPhoneAuthBottomSheet(context),
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: Divider(
                                  color: AppTheme.dividerColor(theme))),
                          const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text("or")),
                          Expanded(
                              child: Divider(
                                  color: AppTheme.dividerColor(theme))),
                        ]),
                        const SizedBox(height: 16),
                        _buildLoginButton(
                          text: "Continue with Google",
                          icon: Image.asset('assets/google_logo.png',
                              height: 22, width: 22),
                          onPressed:
                          _isGoogleLoading ? null : _googleSignInMethod,
                          isLoading: _isGoogleLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPhoneAuthBottomSheet(BuildContext context) {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor(Theme.of(context)),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: AppTheme.elevatedShadow(Theme.of(context)),
            ),
            padding: AppTheme.mediumPadding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor(Theme.of(context)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  "Enter Phone Number",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary(Theme.of(context)),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "We'll send you a verification code",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary(Theme.of(context)),
                  ),
                ),
                const SizedBox(height: 24),
                Form(key: _formKey, child: _buildPhoneInput(context)),
                const SizedBox(height: 24),
                _buildContinueButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_phoneController.text.length == 10 && !_isLoading)
            ? () {
          Navigator.pop(context);
          _verifyPhoneNumber(context);
        }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor(theme),
          foregroundColor: AppTheme.textOnPrimary(theme),
          shape: RoundedRectangleBorder(borderRadius: AppTheme.mediumRadius),
        ),
        child: _isLoading
            ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2))
            : const Text("Continue"),
      ),
    );
  }
}
