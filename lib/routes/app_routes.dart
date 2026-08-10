// lib/routes/app_routes.dart
import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/starting_screen/login_screen.dart';
import '../screens/starting_screen/signup_screen.dart';
import '../screens/starting_screen/splash_screen.dart';
import '../screens/starting_screen/ForgotPassScreen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    login: (context) => const LoginScreen(),
    signup: (context) => const SignupScreen(),
    forgotPassword: (context) => const ForgotPassScreen(),
  };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPassScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Page not found: ${settings.name}'),
            ),
          ),
        );
    }
  }
}