// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pomodoro/core/data_provider.dart';
import 'package:pomodoro/providers/ThemeProvider.dart';
import 'package:pomodoro/providers/UserAuthProvider.dart';
import 'package:pomodoro/screens/Event_Maneger/providers/event_provider.dart';
import 'package:pomodoro/screens/Focus%20Timer/provider/timer_provider.dart';
import 'package:pomodoro/screens/Profile/providers/profile_provider.dart';
import 'package:pomodoro/screens/Task_manager/providers/task_provider.dart';
import 'package:pomodoro/screens/starting_screen/splash_screen.dart';
import 'package:pomodoro/services/ActivityTrackerService.dart';
import 'package:pomodoro/services/firebase_options.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart'; // ✅ Import AppRoutes

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Enable Firestore persistence for offline support
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Only set persistence on web platforms
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }

    print('✅ Firebase initialized successfully');

  } catch (e) {
    print('⚠️ Firebase initialization error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        // Order matters - DataProvider before UserAuthProvider
        ChangeNotifierProvider(create: (_) => DataProvider()),
        ChangeNotifierProvider(create: (_) => UserAuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        Provider<ActivityTrackerService>(
          create: (_) => ActivityTrackerService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize providers after widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeProviders();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _trackAppUsage();
    }
  }

  void _initializeProviders() {
    try {
      final authProvider = context.read<UserAuthProvider>();
      final dataProvider = context.read<DataProvider>();

      // Initialize UserAuthProvider with DataProvider reference
      authProvider.initialize(dataProvider);

      print('✅ Providers initialized successfully');
    } catch (e) {
      print('❌ Error initializing providers: $e');
    }
  }

  void _trackAppUsage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordActivityIfAuthenticated();
    });
  }

  Future<void> _recordActivityIfAuthenticated() async {
    try {
      if (!mounted) return;

      final authProvider = context.read<UserAuthProvider>();
      if (authProvider.isAuthenticated) {
        final dataProvider = context.read<DataProvider>();
        await dataProvider.recordActivity();
      }
    } catch (e) {
      // Silent fail - app usage tracking is non-critical
      print('⚠️ Activity tracking error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Cadance',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.white,
            brightness: Brightness.light,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
            ),
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: Colors.grey[900],
            brightness: Brightness.dark,
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.grey[900],
            ),
            fontFamily: 'Roboto',
          ),
          themeMode: themeProvider.themeMode,
          // ✅ Use routes for navigation
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}