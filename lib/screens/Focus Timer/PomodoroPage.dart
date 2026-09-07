// lib/screens/Focus_Timer/pomodoro_page.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pomodoro/screens/Focus%20Timer/provider/timer_provider.dart';
import 'package:pomodoro/screens/Focus%20Timer/services/PhoneLockService.dart';
import 'package:pomodoro/services/forced_return_service.dart';
import 'package:pomodoro/screens/Focus%20Timer/widgets/SessionCounterWidget.dart';
import 'package:pomodoro/screens/Focus%20Timer/widgets/radial_menu_button.dart';
import 'package:pomodoro/services/firebase_service.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'package:pomodoro/widgets/PopupForm.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/data_provider.dart';
import '../Focus Timer/components/timer_card.dart';

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> with WidgetsBindingObserver {
  // Timer settings
  int _studyMin = 25, _breakMin = 5, _totalSessions = 4;
  String _selectedTimer = '25/5 Micro', _focusWork = 'Focus Session';
  Color _timerColor = Colors.green;
  bool _notifEnabled = true, _hasFocus = false, _focusMode = false, _isRunning = false;
  bool _isBreakPhase = false;
  bool _allSessionsComplete = false;
  bool _isForcedReturnActive = false;
  bool _isDisposed = false;
  bool _isFullLockActive = false;
  bool _isInitialized = false;

  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupChannels();
    _initializeServices();
    _syncNotificationState();
    _restoreState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _loadStats();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _saveState();
    if (_focusMode && _isRunning && !_isBreakPhase) {
      PhoneLockService.disableFullLock();
    }
    ForcedReturnService.reset();
    super.dispose();
  }

  // ─── STATE PERSISTENCE ───
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pomodoro_state', jsonEncode({
        'studyMin': _studyMin,
        'breakMin': _breakMin,
        'totalSessions': _totalSessions,
        'selectedTimer': _selectedTimer,
        'focusWork': _focusWork,
        'timerColor': _timerColor.value,
        'notifEnabled': _notifEnabled,
        'hasFocus': _hasFocus,
        'focusMode': _focusMode,
        'isRunning': _isRunning,
        'isBreakPhase': _isBreakPhase,
        'allSessionsComplete': _allSessionsComplete,
      }));
    } catch (e) {
      print('Error saving state: $e');
    }
  }

  Future<void> _restoreState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateString = prefs.getString('pomodoro_state');
      if (stateString != null) {
        final state = jsonDecode(stateString) as Map<String, dynamic>;
        setState(() {
          _studyMin = state['studyMin'] ?? 25;
          _breakMin = state['breakMin'] ?? 5;
          _totalSessions = state['totalSessions'] ?? 4;
          _selectedTimer = state['selectedTimer'] ?? '25/5 Micro';
          _focusWork = state['focusWork'] ?? 'Focus Session';
          _timerColor = Color(state['timerColor'] ?? Colors.green.value);
          _notifEnabled = state['notifEnabled'] ?? true;
          _hasFocus = state['hasFocus'] ?? false;
          _focusMode = state['focusMode'] ?? false;
          _isRunning = state['isRunning'] ?? false;
          _isBreakPhase = state['isBreakPhase'] ?? false;
          _allSessionsComplete = state['allSessionsComplete'] ?? false;
        });
        _syncNotificationState();
      }
    } catch (e) {
      print('Error restoring state: $e');
    }
  }

  // ─── LOAD STATS ───
  Future<void> _loadStats() async {
    if (_isDisposed || !mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    await dataProvider.refreshTimerStats();
  }

  // ─── INITIALIZATION ───
  void _initializeServices() {
    ForcedReturnService.initialize();
    ForcedReturnService.setOnUserReturned(_handleUserReturned);
    PhoneLockService.initialize();
  }

  void _syncNotificationState() {
    ForcedReturnService.setNotificationsEnabled(_notifEnabled);
  }

  void _setupChannels() {
    const MethodChannel('phone_lock').setMethodCallHandler((call) async {
      if (call.method == 'appWillResignActive' && mounted && !_isDisposed) {
        _warnLock();
      }
      return null;
    });
  }

  // ─── USER RETURN HANDLER ───
  void _handleUserReturned() {
    if (_isDisposed || !mounted) return;

    ForcedReturnService.forceDismissOverlay();
    setState(() {
      _isForcedReturnActive = false;
    });
    if (_isBreakPhase && _isRunning && _focusMode) {
      _enableFullLockIfNeeded();
    }
  }

  // ─── LOCK MANAGEMENT ───
  void _enableFullLockIfNeeded() {
    if (_focusMode && _isRunning && !_isBreakPhase && !_allSessionsComplete) {
      PhoneLockService.enableFullLock();
      _isFullLockActive = true;
    }
  }

  void _disableFullLockIfNeeded() {
    if (_focusMode) {
      PhoneLockService.disableFullLock();
      _isFullLockActive = false;
    }
  }

  // ─── LIFECYCLE TRACKING ───
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !mounted) return;

    if (state == AppLifecycleState.resumed) {
      ForcedReturnService.setAppInForeground(true);
      _loadStats();
      _saveState();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ForcedReturnService.setAppInForeground(false);
      _saveState();
    }

    if (!_focusMode || !_isRunning || _isBreakPhase || _allSessionsComplete) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _warnLock();
      PhoneLockService.enableFullLock();
      _isFullLockActive = true;
    } else if (state == AppLifecycleState.resumed) {
      _checkBreakStatusOnResume();
      PhoneLockService.enableFullLock();
      _isFullLockActive = true;
    }
  }

  Future<void> _checkBreakStatusOnResume() async {
    if (_isDisposed || !mounted) return;
    if (!_notifEnabled) return;

    final needsWarning = await ForcedReturnService.checkBreakStatusOnResume();
    if (needsWarning) {
      setState(() {
        _isForcedReturnActive = true;
      });
      await ForcedReturnService.triggerBreakWarningOnResume();
    }
  }

  // ─── FOCUS LOCK METHODS ───
  void _warnLock() {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.lock, color: _timerColor, size: 24),
          const SizedBox(width: 10),
          const Text('Focus Lock Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        ]),
        content: const Text(
            'Your phone is locked for this study session.\n\nPhone calls are still allowed.',
            style: TextStyle(fontSize: 14)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              backgroundColor: _timerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Stay Focused'),
          ),
        ],
      ),
    );
  }

  // ─── RESET PAGE ───
  void _resetEntirePage() {
    if (_isDisposed || !mounted) return;

    setState(() {
      _studyMin = 25;
      _breakMin = 5;
      _totalSessions = 4;
      _selectedTimer = '25/5 Micro';
      _focusWork = 'Focus Session';
      _timerColor = Colors.green;
      _notifEnabled = true;
      _hasFocus = false;
      _focusMode = false;
      _isRunning = false;
      _isBreakPhase = false;
      _allSessionsComplete = false;
      _isForcedReturnActive = false;
      _isFullLockActive = false;
    });
    _syncNotificationState();
    ForcedReturnService.reset();
    PhoneLockService.disableFullLock();
    _saveState();
  }

  // ─── TIMER CALLBACKS ───
  void _onStart() {
    if (_isDisposed || !mounted) return;
    setState(() {
      _isRunning = true;
      _allSessionsComplete = false;
      _isForcedReturnActive = false;
    });
    if (_focusMode && !_isBreakPhase) {
      PhoneLockService.enableFullLock();
      _isFullLockActive = true;
    }
    _saveState();
  }

  void _onStop() {
    if (_isDisposed || !mounted) return;
    setState(() => _isRunning = false);
    if (_focusMode) {
      PhoneLockService.disableFullLock();
      _isFullLockActive = false;
      ForcedReturnService.dismissForcedReturn();
      _isForcedReturnActive = false;
    }
    _saveState();
  }

  void _onPhaseChange(bool isBreakPhase) {
    if (_isDisposed || !mounted) return;
    setState(() {
      _isBreakPhase = isBreakPhase;
      _allSessionsComplete = false;
      _isForcedReturnActive = false;
    });

    if (_focusMode && _isRunning) {
      if (isBreakPhase) {
        PhoneLockService.disableFullLock();
        _isFullLockActive = false;
        ForcedReturnService.dismissForcedReturn();
      } else {
        PhoneLockService.enableFullLock();
        _isFullLockActive = true;
      }
    }
    _saveState();
  }

  void _onComplete() {
    if (_isDisposed || !mounted) return;
    setState(() {
      _isRunning = false;
      _focusMode = false;
      _isBreakPhase = false;
      _allSessionsComplete = true;
      _isForcedReturnActive = false;
      _isFullLockActive = false;
    });
    PhoneLockService.disableFullLock();
    ForcedReturnService.dismissForcedReturn();
    _saveTimerStats();
    _saveState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDisposed) {
        _resetEntirePage();
        _loadStats();
      }
    });
  }

  void _resetAfterComplete() {
    if (_isDisposed || !mounted) return;
    _resetEntirePage();
    _loadStats();
  }

  Future<void> _saveTimerStats() async {
    if (_isDisposed || !mounted) return;

    try {
      final focusMinutes = _studyMin * _totalSessions;
      const taskCount = 1;

      final timerProvider = Provider.of<TimerProvider>(context, listen: false);
      await timerProvider.recordSession(
        focusMinutes: focusMinutes,
        taskCount: taskCount,
        taskTitle: _focusWork,
      );

      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.refreshTimerStats();

      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Session saved! +${focusMinutes}min focus time'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save stats: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locked = _focusMode && _isRunning && !_isBreakPhase && !_allSessionsComplete;

    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        return WillPopScope(
          onWillPop: () async {
            if (locked) {
              _warnLock();
              PhoneLockService.enableFullLock();
              return false;
            }
            return true;
          },
          child: Scaffold(
            backgroundColor: isDark ? const Color(0xFF0A1A15) : AppColors.bg,
            body: SafeArea(
              child: Stack(
                children: [
                  // Main content - No AbsorbPointer or GestureDetector wrapping
                  CustomScrollView(
                    key: const ValueKey('pomodoro_scroll_view'),
                    physics: locked
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Stats at the top
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: _buildStats(isDark, dataProvider),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // Header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildHeader(isDark, locked),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),

                      // Timer Card - WRAPPED CALLBACKS
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: TimerCard(
                            // Use a simple key or null
                            key: _hasFocus ? const ValueKey('timer_card') : null,
                            studyMinutes: _studyMin,
                            breakMinutes: _breakMin,
                            selectedTimer: _selectedTimer,
                            focusWorkName: _hasFocus ? _focusWork : 'Focus Session',
                            timerColor: _timerColor,
                            totalSessions: _totalSessions,
                            isFocusModeLocked: _focusMode,
                            isAllSessionsComplete: _allSessionsComplete,
                            notificationsEnabled: _notifEnabled,
                            onTimerStarted: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_isDisposed) {
                                  _onStart();
                                }
                              });
                            },
                            onTimerStopped: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_isDisposed) {
                                  _onStop();
                                }
                              });
                            },
                            onAllSessionsComplete: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_isDisposed) {
                                  _onComplete();
                                }
                              });
                            },
                            onPhaseChange: (isBreakPhase) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_isDisposed) {
                                  _onPhaseChange(isBreakPhase);
                                }
                              });
                            },
                            onResetAfterComplete: () {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted && !_isDisposed) {
                                  _resetAfterComplete();
                                }
                              });
                            },
                          ),
                        ),
                      ),

                      // Tips
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildTips(isDark),
                        ),
                      ),

                      // Bottom spacing
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),

                  // Full screen lock overlay - This blocks all interactions when locked
                  if (locked)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: () {
                          _warnLock();
                          PhoneLockService.enableFullLock();
                        },
                        child: Container(
                          color: Colors.transparent,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade800 : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.lock_outline, size: 48, color: _timerColor),
                                  const SizedBox(height: 12),
                                  Text(
                                    '🔒 Focus Mode Active',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Phone is locked for this session',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Radial Menu Button - Only show when not locked
                  if (!locked && !_allSessionsComplete)
                    Positioned(
                      bottom: 120,
                      right: 26,
                      child: RadialMenuButton(
                        key: const ValueKey('radial_menu_button'),
                        isDarkMode: isDark,
                        onTimerSelected: _onTimerSelected,
                        selectedTimer: _selectedTimer,
                        isLocked: locked,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── BUILD HELPERS ───
  Widget _buildHeader(bool isDark, bool locked) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              'Focus Timer',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hasFocus ? '$_selectedTimer · $_focusWork' : 'Tap + to start a focus session',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF6E9584) : AppColors.inkSoft,
                  ),
                ),
                if (_focusMode && !_isRunning && _hasFocus && !_allSessionsComplete) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.lock_outline, size: 14, color: _timerColor),
                ],
                if (locked) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.lock, size: 14, color: _timerColor),
                ],
              ],
            ),
            if (locked) _lockBanner(),
            if (_focusMode && !_isRunning && _hasFocus && !_allSessionsComplete) _infoBanner(),
            if (_focusMode && _isRunning && _isBreakPhase && _hasFocus && !_allSessionsComplete) _breakBanner(),
            if (_focusMode && _isForcedReturnActive) _forcedReturnBanner(),
          ],
        ),
      ),
    );
  }

  Widget _lockBanner() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red.shade400),
              const SizedBox(width: 6),
              Text(
                '🔒 Phone Locked - No Exit',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoBanner() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _timerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _timerColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: _timerColor),
              const SizedBox(width: 6),
              Text(
                'Press Start to activate lock',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _timerColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _breakBanner() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.coffee, size: 14, color: Colors.orange.shade400),
              const SizedBox(width: 6),
              Text(
                '☕ Break Time - Phone Unlocked',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _forcedReturnBanner() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.alarm, size: 14, color: Colors.red.shade600),
              const SizedBox(width: 6),
              Text(
                '⏰ Break ending! Return to app!',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTips(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2E27) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lightbulb_outline, color: _timerColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _hasFocus
                  ? 'Take a $_breakMin-minute break after each session.'
                  : 'Tap the + button to start your first focus session!',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF6E9584) : AppColors.inkSoft,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool isDark, DataProvider dataProvider) {
    final todayMinutes = dataProvider.todayFocusMinutes;
    final weekMinutes = dataProvider.weekFocusMinutes;
    final streak = dataProvider.streak;
    final totalTasks = dataProvider.grandTotalTaskCount;

    final todayDisplay = todayMinutes > 0 ? '${todayMinutes}m' : '0m';
    final weekDisplay = weekMinutes > 0 ? '${weekMinutes}m' : '0m';
    final streakDisplay = streak > 0 ? '$streak 🔥' : '0';
    final tasksDisplay = totalTasks > 0 ? '$totalTasks' : '0';

    return Container(
      key: ValueKey('stats_${todayMinutes}_$streak'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1D2E27) : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat(Icons.check_circle_outline, todayDisplay, 'Today', isDark),
          Container(width: 1, height: 40, color: isDark ? Colors.white.withOpacity(0.05) : AppColors.border),
          _stat(Icons.local_fire_department, streakDisplay, 'Streak', isDark),
          Container(width: 1, height: 40, color: isDark ? Colors.white.withOpacity(0.05) : AppColors.border),
          _stat(Icons.task_alt, tasksDisplay, 'Tasks', isDark),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String val, String label, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 20, color: isDark ? const Color(0xFF4ECDC4) : AppColors.primaryLight),
        const SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.ink,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF6E9584) : AppColors.inkSoft,
          ),
        ),
      ],
    );
  }

  // ─── TIMER SETUP ───
  void _onTimerSelected(String label, int study, int break_, Color color) {
    if (_isDisposed || !mounted) return;
    if (_focusMode && _isRunning) {
      _showFocusModeError();
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogState = _DialogState(
      sessions: _totalSessions,
      notifEnabled: _notifEnabled,
      focusMode: _focusMode,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => UniversalPopupForm(
          title: 'Focus Session',
          icon: Icons.timer,
          accentColor: color,
          primaryButtonText: 'Save Settings',
          secondaryButtonText: 'Cancel',
          fields: [
            FormFieldConfig(
              key: 'focusWork',
              type: FormFieldType.text,
              hint: 'What are you focusing on?',
              prefixIcon: Icons.bookmark_outline,
              initialValue: _hasFocus ? _focusWork : null,
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            FormFieldConfig(
              key: 'sessionCount',
              type: FormFieldType.custom,
              customWidget: _buildSessionSection(isDark, color, dialogState, setDlg),
            ),
          ],
          onSubmit: (data) {
            if (_isDisposed || !mounted) return;
            setState(() {
              _studyMin = study;
              _breakMin = break_;
              _selectedTimer = label;
              _timerColor = color;
              _focusWork = data['focusWork'] as String;
              _totalSessions = dialogState.sessions;
              _notifEnabled = dialogState.notifEnabled;
              _focusMode = dialogState.focusMode;
              _hasFocus = true;
              _allSessionsComplete = false;
              _isForcedReturnActive = false;
              _isFullLockActive = false;
            });
            _syncNotificationState();
            _saveState();
          },
        ),
      ),
    );
  }

  void _showFocusModeError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Cannot change timer while focus mode is active'),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSessionSection(bool isDark, Color color, _DialogState dialogState, StateSetter setDlg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.repeat, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              'Sessions',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      dialogState.focusMode = !dialogState.focusMode;
                      setDlg(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: dialogState.focusMode ? color.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: dialogState.focusMode ? Border.all(color: color.withOpacity(0.3), width: 1.5) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            dialogState.focusMode ? Icons.lock : Icons.lock_open,
                            size: 16,
                            color: dialogState.focusMode ? color : Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      dialogState.notifEnabled = !dialogState.notifEnabled;
                      setDlg(() {});
                      ForcedReturnService.setNotificationsEnabled(dialogState.notifEnabled);
                    },
                    child: Tooltip(
                      message: dialogState.notifEnabled
                          ? 'Notifications ON - Break warning enabled'
                          : 'Notifications OFF - Break warning disabled',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        decoration: BoxDecoration(
                          color: dialogState.notifEnabled ? color.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              dialogState.notifEnabled ? Icons.notifications_active : Icons.notifications_off,
                              size: 18,
                              color: dialogState.notifEnabled ? color : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SessionCounterWidget(
          initialValue: dialogState.sessions,
          accentColor: color,
          onChanged: (v) {
            dialogState.sessions = v;
            setDlg(() {});
          },
        ),
      ],
    );
  }
}

// Helper class for dialog state
class _DialogState {
  int sessions;
  bool notifEnabled;
  bool focusMode;

  _DialogState({
    required this.sessions,
    required this.notifEnabled,
    required this.focusMode,
  });
}