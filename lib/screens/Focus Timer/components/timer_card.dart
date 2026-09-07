// lib/screens/home/components/timer_card.dart
import 'package:flutter/material.dart';
import 'package:pomodoro/utilites/app_colors.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/forced_return_service.dart';
import '../services/PhoneLockService.dart';

// ─── TIMER STATE MANAGER ───
class _TimerStateManager {
  static const String _key = 'timer_card_state';

  static Future<void> saveState(Map<String, dynamic> state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(state);
      await prefs.setString(_key, jsonString);
    } catch (e) {
      print('Error saving timer state: $e');
    }
  }

  static Future<Map<String, dynamic>?> getState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);
      if (jsonString != null) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting timer state: $e');
      return null;
    }
  }

  static Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      print('Error clearing timer state: $e');
    }
  }
}

class TimerCard extends StatefulWidget {
  final int studyMinutes;
  final int breakMinutes;
  final String selectedTimer;
  final String focusWorkName;
  final Color timerColor;
  final int totalSessions;
  final bool isFocusModeLocked;
  final bool isAllSessionsComplete;
  final bool notificationsEnabled;
  final VoidCallback? onTimerStarted;
  final VoidCallback? onTimerStopped;
  final VoidCallback? onAllSessionsComplete;
  final VoidCallback? onResetAfterComplete;
  final Function(bool isBreakPhase)? onPhaseChange;

  const TimerCard({
    super.key,
    required this.studyMinutes,
    required this.breakMinutes,
    required this.selectedTimer,
    this.focusWorkName = 'Focus Session',
    this.timerColor = AppColors.primaryLight,
    this.totalSessions = 4,
    this.isFocusModeLocked = false,
    this.isAllSessionsComplete = false,
    this.notificationsEnabled = true,
    this.onTimerStarted,
    this.onTimerStopped,
    this.onAllSessionsComplete,
    this.onResetAfterComplete,
    this.onPhaseChange,
  });

  @override
  State<TimerCard> createState() => _TimerCardState();
}

class _TimerCardState extends State<TimerCard> with TickerProviderStateMixin, WidgetsBindingObserver {
  // Timer state
  bool _isRunning = false;
  bool _isStudyPhase = true;
  bool _isInitialized = false;
  bool _hasStartedOnce = false;

  // Timer values
  int _totalSeconds = 0;
  int _remainingSeconds = 0;
  int _elapsedSeconds = 0;
  double _progress = 0.0;

  // Session tracking
  int _completedSessions = 0;
  int _currentSession = 1;

  // Break warning
  bool _breakWarningTriggered = false;
  bool _isWaitingForUserReturn = false;

  // Lock state
  bool _isPausedByBackground = false;
  bool _isFullLockActive = false;

  // Timers and controllers
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waterAnimationController;
  late AnimationController _placeholderAnimController;
  late Animation<double> _placeholderRotationAnim;
  late Animation<double> _placeholderScaleAnim;
  late Animation<double> _placeholderOpacityAnim;
  late AnimationController _sessionAnimController;
  late Animation<double> _sessionScaleAnimation;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationScale;
  late Animation<double> _celebrationRotation;
  late Animation<double> _celebrationOpacity;

  // Flag to prevent duplicate operations
  bool _isDisposed = false;
  bool _isPhaseSwitching = false;

  List<Color> get _gradientColors {
    if (widget.isAllSessionsComplete) {
      return [Colors.purple.shade400, Colors.pink.shade600];
    }
    if (!_isInitialized) {
      return [Colors.grey.shade400, Colors.grey.shade600];
    }
    if (_isStudyPhase) {
      return [widget.timerColor, widget.timerColor.withOpacity(0.7)];
    } else {
      return [Colors.orange.shade400, Colors.orange.shade700];
    }
  }

  Color get _shadowColor {
    if (widget.isAllSessionsComplete) return Colors.purple;
    if (!_isInitialized) return Colors.grey;
    return _isStudyPhase ? widget.timerColor : Colors.orange;
  }

  Color get _buttonColor {
    if (widget.isAllSessionsComplete) return Colors.purple;
    if (!_isInitialized) return Colors.grey;
    return _isStudyPhase ? widget.timerColor : Colors.orange.shade700;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _totalSeconds = widget.studyMinutes * 60;
    _remainingSeconds = _totalSeconds;
    _progress = 0.0;

    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waterAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _placeholderAnimController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _placeholderRotationAnim = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _placeholderAnimController, curve: Curves.easeInOut),
    );
    _placeholderScaleAnim = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _placeholderAnimController, curve: Curves.easeInOut),
    );
    _placeholderOpacityAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _placeholderAnimController, curve: Curves.easeInOut),
    );

    _sessionAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _sessionScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _sessionAnimController, curve: Curves.elasticOut),
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _celebrationScale = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    _celebrationRotation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeOut),
    );
    _celebrationOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.easeIn),
    );

    _isInitialized = widget.focusWorkName != 'Focus Session';
    if (_isInitialized) {
      _sessionAnimController.forward();
    }

    if (widget.isAllSessionsComplete) {
      _celebrationController.forward();
    }

    _syncNotificationState();
    ForcedReturnService.setOnUserReturned(_handleUserReturned);

    // Restore timer state
    _restoreTimerState();
  }

  @override
  void didUpdateWidget(TimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isDisposed) return;

    if (oldWidget.notificationsEnabled != widget.notificationsEnabled) {
      _syncNotificationState();
    }

    if (widget.isAllSessionsComplete && !oldWidget.isAllSessionsComplete) {
      _celebrationController.forward();
      _stopTimer();
      setState(() {
        _isRunning = false;
        _pulseController.stop();
        _waterAnimationController.stop();
      });
      _disableFullLockIfNeeded();
    }

    if (!widget.isAllSessionsComplete && oldWidget.isAllSessionsComplete) {
      _resetToDefaultState();
    }

    if (oldWidget.studyMinutes != widget.studyMinutes ||
        oldWidget.breakMinutes != widget.breakMinutes ||
        oldWidget.totalSessions != widget.totalSessions ||
        oldWidget.focusWorkName != widget.focusWorkName) {

      if (widget.focusWorkName != 'Focus Session' && !_isInitialized) {
        setState(() {
          _isInitialized = true;
          _sessionAnimController.forward();
        });
      }

      if (oldWidget.studyMinutes != widget.studyMinutes ||
          oldWidget.breakMinutes != widget.breakMinutes) {
        _resetTimer();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    _saveTimerState();
    _stopTimer();

    _pulseController.dispose();
    _waterAnimationController.dispose();
    _placeholderAnimController.dispose();
    _sessionAnimController.dispose();
    _celebrationController.dispose();

    ForcedReturnService.setOnUserReturned(null);

    // Ensure lock is disabled
    _disableFullLockIfNeeded();

    super.dispose();
  }

  // ─── LIFECYCLE OBSERVER ───
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !mounted) return;

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Save state when going to background
      _saveTimerState();

      if (_isRunning && widget.isFocusModeLocked && _isStudyPhase) {
        // Keep lock active even in background
        PhoneLockService.enableFullLock();
        _isPausedByBackground = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      // Restore state when returning
      _restoreTimerState();

      if (_isRunning && _isPausedByBackground) {
        _isPausedByBackground = false;
        // Timer should continue running
        _startTimer();
      }

      if (widget.isFocusModeLocked && _isRunning && _isStudyPhase) {
        // Re-enable lock on resume
        PhoneLockService.enableFullLock();
        _isFullLockActive = true;
      }
    }
  }

  // ─── PERSISTENCE ───
  void _saveTimerState() {
    try {
      final Map<String, dynamic> state = {
        'isRunning': _isRunning,
        'isStudyPhase': _isStudyPhase,
        'remainingSeconds': _remainingSeconds,
        'elapsedSeconds': _elapsedSeconds,
        'completedSessions': _completedSessions,
        'currentSession': _currentSession,
        'progress': _progress,
        'totalSeconds': _totalSeconds,
        'hasStartedOnce': _hasStartedOnce,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      _TimerStateManager.saveState(state);
    } catch (e) {
      print('Error saving timer state: $e');
    }
  }

  void _restoreTimerState() {
    try {
      _TimerStateManager.getState().then((state) {
        if (state != null && mounted && !_isDisposed) {
          setState(() {
            _isRunning = state['isRunning'] ?? false;
            _isStudyPhase = state['isStudyPhase'] ?? true;
            _remainingSeconds = state['remainingSeconds'] ?? _totalSeconds;
            _elapsedSeconds = state['elapsedSeconds'] ?? 0;
            _completedSessions = state['completedSessions'] ?? 0;
            _currentSession = state['currentSession'] ?? 1;
            _progress = state['progress'] ?? 0.0;
            _totalSeconds = state['totalSeconds'] ?? _totalSeconds;
            _hasStartedOnce = state['hasStartedOnce'] ?? false;
          });

          // Resume timer if it was running
          if (_isRunning && !_isDisposed) {
            _startTimer();
            if (widget.isFocusModeLocked && _isStudyPhase) {
              PhoneLockService.enableFullLock();
              _isFullLockActive = true;
            }
          }
        }
      });
    } catch (e) {
      print('Error restoring timer state: $e');
    }
  }

  // ─── SYNC NOTIFICATION STATE ───
  void _syncNotificationState() {
    ForcedReturnService.setNotificationsEnabled(widget.notificationsEnabled);
  }

  // ─── LOCK MANAGEMENT ───
  void _enableFullLockIfNeeded() {
    if (widget.isFocusModeLocked && _isRunning && _isStudyPhase && !_isFullLockActive) {
      PhoneLockService.enableFullLock();
      _isFullLockActive = true;
      print('🔒 Full lock enabled');
    }
  }

  void _disableFullLockIfNeeded() {
    if (_isFullLockActive) {
      PhoneLockService.disableFullLock();
      _isFullLockActive = false;
      print('🔓 Full lock disabled');
    }
  }

  // ─── TIMER MANAGEMENT ───
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _startTimer() {
    _stopTimer(); // Cancel any existing timer

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
          _elapsedSeconds++;
          _updateProgress();

          // Save state periodically
          if (_elapsedSeconds % 10 == 0) {
            _saveTimerState();
          }

          // Break warning
          if (!_isStudyPhase &&
              !_breakWarningTriggered &&
              _remainingSeconds <= 10 &&
              widget.notificationsEnabled &&
              _remainingSeconds > 0) {
            _breakWarningTriggered = true;
            _triggerBreakWarning();
          }
        } else {
          timer.cancel();
          _switchPhase();
        }
      });
    });
  }

  void _updateProgress() {
    if (_totalSeconds <= 0) {
      _progress = 0.0;
      return;
    }
    _progress = (_elapsedSeconds / _totalSeconds).clamp(0.0, 1.0);
  }

  // ─── TOGGLE TIMER ───
  void _toggleTimer() {
    if (_isDisposed || !mounted) return;
    if (!_isInitialized) return;
    if (widget.isAllSessionsComplete) return;

    if (widget.isFocusModeLocked && _isRunning && _isStudyPhase) {
      _showFocusModeWarning();
      return;
    }

    setState(() {
      _isRunning = !_isRunning;
      if (_isRunning) {
        _hasStartedOnce = true;
        _pulseController.repeat(reverse: true);
        _waterAnimationController.repeat();
        widget.onTimerStarted?.call();
        _startTimer();

        // Enable full lock when starting in focus mode
        _enableFullLockIfNeeded();
      } else {
        _pulseController.stop();
        _pulseController.value = 0;
        _waterAnimationController.stop();
        widget.onTimerStopped?.call();
        _stopTimer();

        // Disable lock when paused
        _disableFullLockIfNeeded();
      }
      _saveTimerState();
    });
  }

  // ─── RESET TIMER ───
  void _resetTimer() {
    if (_isDisposed || !mounted) return;
    if (widget.isAllSessionsComplete) return;
    if (widget.isFocusModeLocked && _isRunning && _isStudyPhase) {
      _showFocusModeWarning();
      return;
    }

    _stopTimer();
    setState(() {
      _isRunning = false;
      _isStudyPhase = true;
      _currentSession = 1;
      _completedSessions = 0;
      _totalSeconds = widget.studyMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _elapsedSeconds = 0;
      _progress = 0.0;
      _hasStartedOnce = false;
      _breakWarningTriggered = false;
      _isWaitingForUserReturn = false;
      _isPhaseSwitching = false;

      _pulseController.stop();
      _pulseController.value = 0;
      _waterAnimationController.reset();
      _waterAnimationController.stop();
      _sessionAnimController.reset();

      if (_isInitialized) {
        _sessionAnimController.forward();
      }
    });

    widget.onPhaseChange?.call(false);
    widget.onTimerStopped?.call();
    _saveTimerState();

    // Ensure lock is disabled on reset
    _disableFullLockIfNeeded();
  }

  // ─── RESET TO DEFAULT ───
  void _resetToDefaultState() {
    if (_isDisposed || !mounted) return;

    _stopTimer();
    setState(() {
      _isRunning = false;
      _isStudyPhase = true;
      _progress = 0.0;
      _isInitialized = false;
      _hasStartedOnce = false;
      _completedSessions = 0;
      _currentSession = 1;
      _breakWarningTriggered = false;
      _isWaitingForUserReturn = false;
      _isPhaseSwitching = false;

      _totalSeconds = widget.studyMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _elapsedSeconds = 0;

      _pulseController.stop();
      _pulseController.value = 0;
      _waterAnimationController.reset();
      _waterAnimationController.stop();
      _sessionAnimController.reset();
      _celebrationController.reset();
      _celebrationController.stop();
    });

    widget.onResetAfterComplete?.call();
    widget.onTimerStopped?.call();
    _TimerStateManager.clearState();
    _disableFullLockIfNeeded();
  }

  // ─── PHASE SWITCHING ───
  void _switchPhase() {
    if (_isDisposed || !mounted) return;
    if (_isPhaseSwitching) return;
    _isPhaseSwitching = true;

    if (_isStudyPhase) {
      // Study phase completed
      _completedSessions++;

      if (_completedSessions >= widget.totalSessions) {
        widget.onPhaseChange?.call(false);
        widget.onAllSessionsComplete?.call();
        widget.onTimerStopped?.call();
        _isPhaseSwitching = false;
        _disableFullLockIfNeeded();

        _showPhaseCompletionDialog(
          'All Sessions Complete! 🎉',
          'Congratulations! You\'ve completed all ${widget.totalSessions} sessions!',
        );
        _resetToDefaultState();
        return;
      }

      // Switch to break
      _isStudyPhase = false;
      _breakWarningTriggered = false;
      _isWaitingForUserReturn = false;
      widget.onPhaseChange?.call(true);
      _totalSeconds = widget.breakMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _elapsedSeconds = 0;
      _progress = 0.0;
      _isPhaseSwitching = false;

      // Disable lock during break
      _disableFullLockIfNeeded();

      _showPhaseCompletionDialog(
        'Session $_currentSession Complete! 🎉',
        'Great job! Time for a ${widget.breakMinutes}-minute break.\n${widget.totalSessions - _completedSessions} sessions remaining.',
      );

      // Auto-start break
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isDisposed && !widget.isAllSessionsComplete) {
          setState(() {
            _isRunning = true;
            _waterAnimationController.repeat();
            widget.onTimerStarted?.call();
            _startTimer();
          });
          _saveTimerState();
        }
      });
    } else {
      // Break completed, switch to study
      _currentSession++;
      _isStudyPhase = true;
      _breakWarningTriggered = false;
      _isWaitingForUserReturn = false;
      _isPhaseSwitching = false;
      widget.onPhaseChange?.call(false);
      _totalSeconds = widget.studyMinutes * 60;
      _remainingSeconds = _totalSeconds;
      _elapsedSeconds = 0;
      _progress = 0.0;

      // Re-enable lock for study phase
      _enableFullLockIfNeeded();

      _sessionAnimController.reset();
      _sessionAnimController.forward();

      _showPhaseCompletionDialog(
        'Break Complete! 💪',
        'Starting Session $_currentSession of ${widget.totalSessions}',
      );

      // Auto-start study session
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && !_isDisposed && !widget.isAllSessionsComplete) {
          setState(() {
            _isRunning = true;
            _waterAnimationController.repeat();
            widget.onTimerStarted?.call();
            _startTimer();
          });
          _saveTimerState();
        }
      });
    }
  }

  // ─── BREAK WARNING ───
  Future<void> _triggerBreakWarning() async {
    if (!widget.notificationsEnabled) return;
    if (_isDisposed || !mounted) return;

    if (ForcedReturnService.isAppInForeground()) {
      _showInAppBreakWarning();
      return;
    }

    if (Theme.of(context).platform == TargetPlatform.android) {
      _isWaitingForUserReturn = true;
      await ForcedReturnService.showForcedReturn(
        title: '⚠️ BREAK ENDING IN ${_remainingSeconds}s!',
        subtitle: 'Return to app immediately!',
        countdown: _remainingSeconds,
        playAlarm: true,
      );
    } else {
      _showIOSBreakAlert();
    }
  }

  void _showInAppBreakWarning() {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.alarm, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text('⏰ Break Ending Soon!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your break ends in $_remainingSeconds seconds!',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                _remainingSeconds.toString(),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are already in the app! Stay focused! 💪',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('✅ Stay Focused'),
          ),
        ],
      ),
    );
  }

  Future<void> _showIOSBreakAlert() async {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Break Ending Soon!'),
        content: Text(
          'Your break ends in $_remainingSeconds seconds!\n\nPlease return to the app to continue focusing.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── USER RETURNED ───
  void _handleUserReturned() {
    if (_isDisposed || !mounted) return;

    ForcedReturnService.forceDismissOverlay();
    setState(() {
      _isWaitingForUserReturn = false;
      _breakWarningTriggered = false;
    });

    if (_remainingSeconds <= 0) {
      _switchPhase();
    } else {
      _isRunning = true;
      _startTimer();
      widget.onTimerStarted?.call();
      _showWelcomeBack();
    }
  }

  void _showWelcomeBack() {
    if (_isDisposed || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            const Text('✅ Welcome back! Focus mode activated!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─── DIALOGS ───
  void _showFocusModeWarning() {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.lock, color: widget.timerColor, size: 24),
          const SizedBox(width: 10),
          const Text('Focus Mode Active', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
        ]),
        content: const Text(
          'Focus Mode is enabled. You cannot pause or reset the timer during study sessions.\n\nStay focused and complete your sessions!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: widget.timerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showPhaseCompletionDialog(String title, String message) {
    if (_isDisposed || !mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: widget.timerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ─── HELPERS ───
  String _getFormattedTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.isAllSessionsComplete
          ? _buildCompletionContent()
          : _isInitialized
          ? _buildTimerContent()
          : _buildPlaceholderContent(),
    );
  }

  Widget _buildCompletionContent() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.scale(
              scale: _celebrationScale.value,
              child: Transform.rotate(
                angle: _celebrationRotation.value * 0.3,
                child: Opacity(
                  opacity: _celebrationOpacity.value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _celebrationOpacity.value,
              duration: const Duration(milliseconds: 500),
              child: Column(
                children: [
                  const Text(
                    '🎉 Congratulations! 🎉',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You completed all ${widget.totalSessions} sessions!',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        'Total Focus: ${widget.totalSessions * widget.studyMinutes} min',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      _resetToDefaultState();
                      widget.onResetAfterComplete?.call();
                      widget.onTimerStopped?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Start New Session',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaceholderContent() {
    return AnimatedBuilder(
      animation: _placeholderAnimController,
      builder: (context, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Transform.rotate(
              angle: _placeholderRotationAnim.value,
              child: Transform.scale(
                scale: _placeholderScaleAnim.value,
                child: Opacity(
                  opacity: _placeholderOpacityAnim.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.timer,
                      color: Colors.white70,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _placeholderAnimController,
                  builder: (context, child) {
                    final delay = index * 0.3;
                    final value = (_placeholderAnimController.value + delay) % 1.0;
                    final opacity = 0.3 + (math.sin(value * 2 * math.pi) + 1) * 0.35;
                    return Container(
                      key: ValueKey('placeholder_dot_$index'), // ADDED: Unique key
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(opacity.clamp(0.0, 1.0)),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a timer to start focusing',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button below to choose a timer',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
          ],
        );
      },
    );
  }

  Widget _buildTimerContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  key: ValueKey('status_indicator_$_isRunning'), // ADDED: Unique key
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isRunning
                        ? Colors.greenAccent
                        : _remainingSeconds == _totalSeconds
                        ? Colors.white
                        : Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isStudyPhase
                      ? (_isRunning ? 'Studying...' : 'Ready to Study')
                      : (_isRunning ? 'Break Time ☕' : 'Break Paused'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _getFormattedTime(),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _sessionScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _sessionScaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.repeat, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Session $_currentSession of ${widget.totalSessions}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.totalSessions, (index) {
            final isCompleted = index < _completedSessions;
            final isCurrent = index == _currentSession - 1 && _isStudyPhase;

            return AnimatedContainer(
              key: ValueKey('session_indicator_$index'), // ADDED: Unique key
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isCurrent ? 28 : 20,
              height: 6,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.white
                    : isCurrent
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),

        const SizedBox(height: 16),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: SizedBox(
                width: 90,
                height: 90,
                child: WaterGlassProgress(
                  key: ValueKey('water_glass_${_isStudyPhase}_${_progress.toStringAsFixed(3)}'), // ADDED: Unique key with progress
                  progress: _progress,
                  animation: _waterAnimationController,
                  isStudyPhase: _isStudyPhase,
                  timerColor: widget.timerColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current session',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                  ),
                  Text(
                    _isStudyPhase ? 'Focus · ${widget.focusWorkName}' : 'Break · Relax',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Completed: $_completedSessions of ${widget.totalSessions} sessions',
                    style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: _toggleTimer,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isRunning ? Colors.white.withOpacity(0.2) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isRunning ? Icons.pause : Icons.play_arrow,
                                  size: 16,
                                  color: _isRunning ? Colors.white : _buttonColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isRunning ? 'Pause' : 'Start',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                    color: _isRunning ? Colors.white : _buttonColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _resetTimer,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.refresh_rounded, size: 18, color: Colors.white.withOpacity(0.9)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 3,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            widthFactor: _progress,
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── WATER GLASS PROGRESS ───
class WaterGlassProgress extends StatelessWidget {
  final double progress;
  final AnimationController animation;
  final bool isStudyPhase;
  final Color timerColor;

  const WaterGlassProgress({
    super.key,
    required this.progress,
    required this.animation,
    required this.isStudyPhase,
    required this.timerColor,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure progress is valid
    final safeProgress = progress.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: WaterGlassPainter(
            progress: safeProgress,
            waveOffset: animation.value * 2 * math.pi,
            isStudyPhase: isStudyPhase,
            timerColor: timerColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(safeProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isStudyPhase ? 'Study' : 'Break',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white.withOpacity(0.8),
                    shadows: const [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1))],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── WATER GLASS PAINTER ───
class WaterGlassPainter extends CustomPainter {
  final double progress;
  final double waveOffset;
  final bool isStudyPhase;
  final Color timerColor;

  WaterGlassPainter({
    required this.progress,
    required this.waveOffset,
    required this.isStudyPhase,
    required this.timerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2 - 2;

    final glassPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(centerX, centerY), radius, glassPaint);

    final glassBgPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius, glassBgPaint);

    final waterHeight = size.height * (1 - progress);
    final waterTop = waterHeight.clamp(0.0, size.height);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: Offset(centerX, centerY), radius: radius)));

    if (progress > 0) {
      final waterPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isStudyPhase
              ? [timerColor.withOpacity(0.4), timerColor.withOpacity(0.7), timerColor.withOpacity(0.9)]
              : [Colors.orange.withOpacity(0.4), Colors.orange.withOpacity(0.7), Colors.orange.withOpacity(0.9)],
        ).createShader(Rect.fromLTWH(0, waterTop - 10, size.width, size.height - waterTop + 10));

      final waterPath = Path();
      waterPath.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        final waveY = waterTop +
            math.sin((x / size.width * 2 * math.pi) + waveOffset) * 3.0 +
            math.sin((x / size.width * 4 * math.pi) + waveOffset * 1.5) * 2.0;
        waterPath.lineTo(x, waveY.clamp(0.0, size.height));
      }
      waterPath.lineTo(size.width, size.height);
      waterPath.close();
      canvas.drawPath(waterPath, waterPaint);

      if (progress < 1.0) {
        final highlightPaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final highlightPath = Path();
        highlightPath.moveTo(0, waterTop);
        for (double x = 0; x <= size.width; x++) {
          final waveY = waterTop +
              math.sin((x / size.width * 2 * math.pi) + waveOffset) * 3.0 +
              math.sin((x / size.width * 4 * math.pi) + waveOffset * 1.5) * 2.0;
          highlightPath.lineTo(x, waveY.clamp(0.0, size.height));
        }
        canvas.drawPath(highlightPath, highlightPaint);
      }

      if (progress > 0.1 && progress < 0.95) {
        final bubblePaint = Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        for (int i = 0; i < 3; i++) {
          final bubbleX = centerX + math.sin(waveOffset + i * 2.0) * (radius * 0.5);
          final bubbleY = centerY + math.cos(waveOffset + i * 1.5) * (radius * 0.3) + (1 - progress) * radius * 0.8;
          final bubbleRadius = 3.0 + math.sin(waveOffset * 2 + i) * 1.5;
          canvas.drawCircle(
            Offset(bubbleX, bubbleY.clamp(waterTop + 5, size.height - 5)),
            bubbleRadius,
            bubblePaint,
          );
        }
      }
    }

    canvas.restore();
    canvas.drawCircle(Offset(centerX, centerY), radius, glassPaint);
  }

  @override
  bool shouldRepaint(covariant WaterGlassPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveOffset != waveOffset ||
        oldDelegate.isStudyPhase != isStudyPhase ||
        oldDelegate.timerColor != timerColor;
  }
}