// lib/services/focus_lock_service.dart
import 'dart:ui';
import 'dart:io' show Platform;
import '../services/PhoneLockService.dart';
import '../../../services/forced_return_service.dart';

class FocusLockService {
  static bool _isLocked = false;
  static VoidCallback? _onLockViolated;
  static int _lockDurationMinutes = 0;
  static bool _isInBreak = false;
  static bool _breakWarningTriggered = false;

  static bool get isLocked => _isLocked;
  static bool get isInBreak => _isInBreak;

  // ─── LOCK METHODS ───

  static Future<void> activateLock({
    required int durationMinutes,
    VoidCallback? onLockViolated,
  }) async {
    _isLocked = true;
    _lockDurationMinutes = durationMinutes;
    _onLockViolated = onLockViolated;
    _isInBreak = false;
    _breakWarningTriggered = false;

    await PhoneLockService.enableLock();
    print('🔒 Focus lock activated for $durationMinutes minutes');
  }

  static Future<void> releaseLock() async {
    _isLocked = false;
    _lockDurationMinutes = 0;
    _onLockViolated = null;
    _isInBreak = false;
    _breakWarningTriggered = false;

    await PhoneLockService.disableLock();
    print('🔓 Focus lock released');
  }

  static void handleLockViolation() {
    if (_isLocked) _onLockViolated?.call();
  }

  // ─── BREAK MANAGEMENT ───

  static Future<void> startBreak(int breakMinutes) async {
    _isInBreak = true;
    _breakWarningTriggered = false;

    // Release lock during break
    await PhoneLockService.disableLock();
    print('☕ Break started for $breakMinutes minutes');

    // Only schedule warning on Android
    if (Platform.isAndroid) {
      // Schedule warning 10 seconds before break ends
      _scheduleBreakWarning(breakMinutes);
    }
  }

  static void _scheduleBreakWarning(int breakMinutes) {
    // Calculate warning time (10 seconds before break ends)
    final warningDelay = Duration(
      minutes: breakMinutes,
      seconds: -10,
    );

    // Only schedule if break is longer than 10 seconds
    if (warningDelay.inSeconds > 0) {
      print('⏰ Break warning scheduled in ${warningDelay.inSeconds} seconds');

      // Use a timer to trigger the warning
      // Note: This timer won't work in background!
      // For background, you need to use AndroidAlarmManager
      Future.delayed(warningDelay, () {
        if (_isInBreak && !_breakWarningTriggered) {
          _triggerBreakWarning();
        }
      });
    }
  }

  static Future<void> _triggerBreakWarning() async {
    if (_breakWarningTriggered) return;
    _breakWarningTriggered = true;

    print('⚠️ Break ending soon! Triggering forced return...');

    // Only on Android
    if (Platform.isAndroid) {
      await ForcedReturnService.showForcedReturn(
        title: '⚠️ BREAK ENDING SOON!',
        subtitle: 'Return to app in 10 seconds',
        countdown: 10,
        playAlarm: true,
      );
    } else {
      // iOS fallback
      print('📱 iOS: Showing break warning notification');
      // You can add iOS notification here
    }
  }

  static Future<void> endBreak() async {
    _isInBreak = false;
    _breakWarningTriggered = false;

    // Re-lock when break ends
    if (_isLocked) {
      await PhoneLockService.enableLock();
      print('🔒 Break ended - Focus lock re-activated');
    }
  }

  // ─── USER RETURN HANDLER ───

  static void handleUserReturned() {
    print('✅ User returned to app');

    // Clear warning state
    _breakWarningTriggered = false;

    // If we're in break and lock is active, re-lock
    if (!_isInBreak && _isLocked) {
      PhoneLockService.enableLock();
    }
  }

  // ─── BACKGROUND CHECKING ───

  static Future<void> checkBreakStatusOnResume() async {
    if (_isInBreak) {
      // Check if break should have ended
      // You'll need to store break end time in SharedPreferences
      // and check against current time
      print('⏰ Checking break status on resume...');

      // This will be handled by ForcedReturnService
      await ForcedReturnService.triggerBreakWarningOnResume();
    }
  }

  // ─── RESET ───

  static Future<void> reset() async {
    _isLocked = false;
    _isInBreak = false;
    _breakWarningTriggered = false;
    _lockDurationMinutes = 0;
    _onLockViolated = null;

    await PhoneLockService.disableLock();
    await ForcedReturnService.reset();
    print('🔄 FocusLockService reset');
  }

  // ─── STATUS CHECKING ───

  static String getStatus() {
    if (_isLocked && !_isInBreak) {
      return '🔒 Locked - Study Mode';
    } else if (_isLocked && _isInBreak) {
      return '☕ Break Mode - Unlocked';
    } else if (!_isLocked && _isInBreak) {
      return '☕ Break Mode - Unlocked';
    } else {
      return '🔓 Unlocked';
    }
  }

  static Future<bool> isDeviceLocked() async {
    return await PhoneLockService.isLocked();
  }
}