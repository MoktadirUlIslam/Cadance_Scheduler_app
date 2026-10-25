// lib/main.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:pomodoro/core/data_provider.dart';
import 'package:pomodoro/providers/ThemeProvider.dart';
import 'package:pomodoro/providers/UserAuthProvider.dart';
import 'package:pomodoro/screens/Event_Maneger/providers/event_provider.dart';
import 'package:pomodoro/screens/Focus%20Timer/provider/timer_provider.dart';
import 'package:pomodoro/screens/Profile/providers/profile_provider.dart';
import 'package:pomodoro/screens/Task_manager/providers/Task_provider.dart';
import 'package:pomodoro/services/ActivityTrackerService.dart';
import 'package:pomodoro/services/firebase_options.dart';
import 'package:pomodoro/services/notification_service.dart';

import 'routes/app_routes.dart';

bool get _supportsLocalNotifications {
  if (kIsWeb) return false;

  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase before creating providers that use it.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error, stackTrace) {
    debugPrint('Firebase initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);

    // Do not launch Firebase-dependent providers without Firebase.
    runApp(const _StartupErrorApp());
    return;
  }

  // Configure persistence separately from Firebase initialization.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(
        Persistence.LOCAL,
      );
    }
  } catch (error, stackTrace) {
    debugPrint('Persistence configuration failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  // Sets up timezones, notification channels, and callbacks.
  // The updated NotificationService does not request permissions here.
  if (_supportsLocalNotifications) {
    try {
      await NotificationService.instance.initialize();
      debugPrint('Notification service initialized');
    } catch (error, stackTrace) {
      // Notification failure should not prevent app startup.
      debugPrint('Notification initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => DataProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserAuthProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TimerProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => EventProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => TaskProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProfileProvider(),
        ),
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

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

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
      _recordActivityIfAuthenticated();
    }
  }

  void _initializeProviders() {
    try {
      final authProvider = context.read<UserAuthProvider>();
      final dataProvider = context.read<DataProvider>();

      authProvider.initialize(dataProvider);

      debugPrint('Providers initialized');
    } catch (error, stackTrace) {
      debugPrint('Provider initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _recordActivityIfAuthenticated() async {
    if (!mounted) return;

    try {
      final authProvider = context.read<UserAuthProvider>();

      if (!authProvider.isAuthenticated) return;

      final dataProvider = context.read<DataProvider>();
      await dataProvider.recordActivity();
    } catch (error) {
      // Activity tracking is non-critical.
      debugPrint('Activity tracking failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Cadence',
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
          initialRoute: AppRoutes.splash,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Cadence could not start.\n'
                    'Please close the app and try again.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}