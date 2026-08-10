// lib/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/widgets/drawer_widget.dart';
import 'package:pomodoro/widgets/dock_widget.dart';
import 'package:pomodoro/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../core/data_provider.dart';
import '../../providers/ThemeProvider.dart';
import '../Event_Maneger/Event_Manager.dart';
import '../Focus Timer/PomodoroPage.dart';
import '../Task_manager/task_manager_page.dart';
import '../Profile/profilescreen.dart';
import 'components/home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<DockWidgetState> _dockKey = GlobalKey<DockWidgetState>();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _selectedIndex = 2;
  bool _isDisposed = false;

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    if (_selectedIndex != index) {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<ThemeProvider, bool>(
          (provider) => provider.isDarkMode,
    );

    final dataProvider = context.watch<DataProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.bg,
      drawer: const CustomDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              scaffoldKey: _scaffoldKey,
              showNotificationBadge: true,
            ),
            // Main content - takes ALL available space
            Expanded(
              child: Column(
                children: [
                  // Main content - takes all available space
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: const [
                        PomodoroPage(),
                        TaskManagerPage(),
                        HomeContent(),
                        EventPage(),
                        Profilescreen(),
                      ],
                    ),
                  ),
                  // Dock - NO background, just the dock widget
                  DockWidget(
                    key: _dockKey,
                    currentIndex: _selectedIndex,
                    onTabSelected: _onTabSelected, // Will be set via provider or callback
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}