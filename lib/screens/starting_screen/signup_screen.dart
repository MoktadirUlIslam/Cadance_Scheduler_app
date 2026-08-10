// lib/screens/starting_screen/signup_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/widgets/cadence_auth_widgets.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // In signup_screen.dart, update _handleSignUp method:
  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Navigate directly to home screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Sign up failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _goToLogin() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
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
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _goToLogin,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FadeTransition(
                        opacity: _brandFade,
                        child: const Text(
                          'Cadence',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 34),

                  SlideTransition(
                    position: _headlineSlide,
                    child: FadeTransition(
                      opacity: _headlineFade,
                      child: const Text(
                        'Create account',
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
                        'Start your study rhythm today.',
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
                                    controller: _usernameController,
                                    label: 'Username',
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Enter a username';
                                      }
                                      if (v.trim().length < 3) {
                                        return 'At least 3 characters';
                                      }
                                      return null;
                                    },
                                  ),
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
                                        return 'Enter a password';
                                      }
                                      if (v.length < 6) {
                                        return 'At least 6 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  CadenceTextField(
                                    controller: _confirmController,
                                    label: 'Confirm password',
                                    obscureText: true,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Confirm your password';
                                      }
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  Consumer<AuthProvider>(
                                    builder: (context, auth, child) {
                                      return CadencePrimaryButton(
                                        label: 'Sign up',
                                        loading: auth.isLoading,
                                        onPressed: () => _handleSignUp(),
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
                                          const TextSpan(
                                              text: 'Already have an account? '),
                                          TextSpan(
                                            text: 'Sign in',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primaryLight,
                                            ),
                                            recognizer: (TapGestureRecognizer()
                                              ..onTap = _goToLogin),
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
}