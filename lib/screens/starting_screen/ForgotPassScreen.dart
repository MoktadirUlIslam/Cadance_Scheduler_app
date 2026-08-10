// lib/screens/starting_screen/forgotpass_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/widgets/cadence_auth_widgets.dart';
import '../../providers/auth_provider.dart';

class ForgotPassScreen extends StatefulWidget {
  const ForgotPassScreen({super.key});

  @override
  State<ForgotPassScreen> createState() => _ForgotPassScreenState();
}

class _ForgotPassScreenState extends State<ForgotPassScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPassword(
      _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _emailSent = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to send reset email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryLight,
                  AppColors.primaryDark,
                ],
              ),
            ),
          ),
          const CadenceBackground(),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Header Section
                  SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reset Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 27,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _emailSent
                                ? 'Check your email for reset instructions.'
                                : 'Enter your email to receive a password reset link.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.68),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Content Card
                  Expanded(
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(26),
                              topRight: Radius.circular(26),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 40,
                                offset: const Offset(0, -14),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: _emailSent
                                ? _buildSuccessView()
                                : _buildEmailForm(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          // Email Icon
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.lock_reset_outlined,
                size: 32,
                color: AppColors.primaryLight,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Email Field
          CadenceTextField(
            controller: _emailController,
            label: 'Email address',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Enter your email address';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Send Button
          Consumer<AuthProvider>(
            builder: (context, auth, child) {
              return CadencePrimaryButton(
                label: 'Send Reset Link',
                loading: auth.isLoading,
                onPressed: () => _handleResetPassword(),
              );
            },
          ),

          const SizedBox(height: 16),

                 ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        // Success Icon
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: Colors.green,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Success Message
        const Text(
          'Email Sent!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent a password reset link to ${_emailController.text.trim()}. Please check your inbox and follow the instructions to reset your password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Tips:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '• Check your spam folder if you don\'t see the email\n'
                    '• The link expires in 1 hour\n'
                    '• If you don\'t receive it, try again',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Resend Button
        Consumer<AuthProvider>(
          builder: (context, auth, child) {
            return OutlinedButton(
              onPressed: auth.isLoading ? null : () => _handleResetPassword(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: AppColors.primaryLight),
              ),
              child: Text(
                auth.isLoading ? 'Sending...' : 'Resend Email',
                style: TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),

        // Back to Login
        Center(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Back to Sign In',
              style: TextStyle(
                color: AppColors.primaryLight,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}