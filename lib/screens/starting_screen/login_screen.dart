// lib/screens/starting_screen/login_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pomodoro/providers/auth_provider.dart';
import 'package:pomodoro/screens/starting_screen/ForgotPassScreen.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/screens/starting_screen/signup_screen.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/widgets/cadence_auth_widgets.dart';
import '../../routes/app_routes.dart';
import '../home/home_screen.dart' show HomeScreen;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entrance;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _headlineFade;
  late final Animation<Offset> _subtextSlide;
  late final Animation<double> _subtextFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _brandFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _headlineFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.10, 0.45, curve: Curves.easeOut),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.10, 0.45, curve: Curves.easeOut),
    ));

    _subtextFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.18, 0.5, curve: Curves.easeOut),
    );
    _subtextSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.18, 0.5, curve: Curves.easeOut),
    ));

    _cardFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
    ));

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // In login_screen.dart, update _handleSignIn method:
  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to home and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false, // This removes all routes including login
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  void _goToSignup() {
    Navigator.push(
      context,
      _slideFadeRoute(const SignupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryDark,   // Lighter teal at top
                  AppColors.primaryLight,  // Darker teal at bottom
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
                  FadeTransition(
                    opacity: _brandFade,
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/logo/app_logo.png',
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Cadence',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 34),

                  SlideTransition(
                    position: _headlineSlide,
                    child: FadeTransition(
                      opacity: _headlineFade,
                      child: const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 27,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SlideTransition(
                    position: _subtextSlide,
                    child: FadeTransition(
                      opacity: _subtextFade,
                      child: Text(
                        'Sign in to keep your study rhythm going.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  Expanded(
                    child: SlideTransition(
                      position: _cardSlide,
                      child: FadeTransition(
                        opacity: _cardFade,
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
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  CadenceTextField(
                                    controller: _emailController,
                                    label: 'Email',
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Enter your email';
                                      }
                                      if (!v.contains('@')) {
                                        return 'Enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  CadenceTextField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    obscureText: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Enter your password';
                                      }
                                      if (v.length < 6) {
                                        return 'At least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  // In login_screen.dart, update the forgot password TextButton:
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => const ForgotPassScreen()),
                                        );
                                      },
                                      child: Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primaryLight,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, child) {
                                      return CadencePrimaryButton(
                                        label: 'Sign in',
                                        loading: auth.isLoading,
                                        onPressed: () => _handleSignIn(),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 18),
                                  Center(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        children: [
                                          const TextSpan(text: "Don't have an account? "),
                                          TextSpan(
                                            text: 'Signup now',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryLight,
                                            ),
                                            recognizer: (TapGestureRecognizer()
                                              ..onTap = _goToSignup),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive reset instructions.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final email = emailController.text.trim();

              if (email.isEmpty || !email.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid email'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final success = await authProvider.resetPassword(email);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Reset email sent! Check your inbox.' : authProvider.error ?? 'Failed to send reset email'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

Route _slideFadeRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}