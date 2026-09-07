// lib/services/focus_lock_service.dart
import 'dart:ui';
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert'; // ADDED for proper JSON serialization
import '../../../services/forced_return_service.dart';
import 'PhoneLockService.dart';

class FocusLockService {
  static bool _isLocked = false;
  static VoidCallback? _onLockViolated;
  static int _lockDurationMinutes = 0;
  static bool _isInBreak = false;
  static bool _breakWarningTriggered = false;
  static Timer? _breakTimer;
  static Timer? _warningTimer;
  static DateTime? _breakEndTime;
  static bool _isFullLockActive = false;

  static bool get isLocked => _isLocked;
  static bool get isInBreak => _isInBreak;
  static bool get isFullLockActive => _isFullLockActive;

  // ─── LOCK METHODS ───

  static Future<void> activateLock({
    required int durationMinutes,
    VoidCallback? onLockViolated,
    bool useFullLock = true,
  }) async {
    _isLocked = true;
    _lockDurationMinutes = durationMinutes;
    _onLockViolated = onLockViolated;
    _isInBreak = false;
    _breakWarningTriggered = false;

    if (useFullLock) {
      await PhoneLockService.enableFullLock();
      _isFullLockActive = true;
      print('🔒 Full focus lock activated for $durationMinutes minutes');
    } else {
      await PhoneLockService.enableLock();
      _isFullLockActive = false;
      print('🔒 Focus lock activated for $durationMinutes minutes');
    }

    // Save state for persistence
    await _saveLockState();
  }

  static Future<void> releaseLock() async {
    _isLocked = false;
    _lockDurationMinutes = 0;
    _onLockViolated = null;
    _isInBreak = false;
    _breakWarningTriggered = false;

    _breakTimer?.cancel();
    _breakTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;
    _breakEndTime = null;

    if (_isFullLockActive) {
      await PhoneLockService.disableFullLock();
      _isFullLockActive = false;
    } else {
      await PhoneLockService.disableLock();
    }

    await _clearLockState();
    print('🔓 Focus lock released');
  }

  static void handleLockViolation() {
    if (_isLocked) _onLockViolated?.call();
  }

  // ─── BREAK MANAGEMENT ───

  static Future<void> startBreak(int breakMinutes) async {
    _isInBreak = true;
    _breakWarningTriggered = false;
    _breakEndTime = DateTime.now().add(Duration(minutes: breakMinutes));

    // Release full lock during break
    if (_isFullLockActive) {
      await PhoneLockService.disableFullLock();
      _isFullLockActive = false;
      print('🔓 Full lock released during break');
    } else {
      await PhoneLockService.disableLock();
    }

    print('☕ Break started for $breakMinutes minutes');
    await _saveLockState();

    // Schedule warnings
    _scheduleBreakWarning(breakMinutes);
    _scheduleBreakEnd(breakMinutes);
  }

  static void _scheduleBreakWarning(int breakMinutes) {
    // Schedule warning 10 seconds before break ends
    final warningDelay = Duration(
      minutes: breakMinutes,
      seconds: -10,
    );

    // Cancel existing timer
    _warningTimer?.cancel();

    if (warningDelay.inSeconds > 0) {
      _warningTimer = Timer(warningDelay, () {
        if (_isInBreak && !_breakWarningTriggered) {
          _triggerBreakWarning();
        }
      });
      print('⏰ Break warning scheduled in ${warningDelay.inSeconds} seconds');
    }
  }

  static void _scheduleBreakEnd(int breakMinutes) {
    // Cancel existing timer
    _breakTimer?.cancel();

    final breakDuration = Duration(minutes: breakMinutes);
    _breakTimer = Timer(breakDuration, () {
      if (_isInBreak) {
        print('⏰ Break ended automatically');
        _onBreakEnded();
      }
    });
    print('⏰ Break end scheduled in $breakMinutes minutes');
  }

  static Future<void> _triggerBreakWarning() async {
    if (_breakWarningTriggered) return;
    _breakWarningTriggered = true;

    print('⚠️ Break ending soon! Triggering forced return...');

    if (Platform.isAndroid) {
      await ForcedReturnService.showForcedReturn(
        title: '⚠️ BREAK ENDING SOON!',
        subtitle: 'Return to app in 10 seconds',
        countdown: 10,
        playAlarm: true,
      );
    } else {
      print('📱 iOS: Showing break warning notification');
      // You can add iOS notification here
    }
  }

  static Future<void> _onBreakEnded() async {
    if (!_isInBreak) return;

    _isInBreak = false;
    _breakWarningTriggered = false;
    _breakEndTime = null;

    // Re-lock when break ends
    if (_isLocked) {
      await PhoneLockService.enableFullLock();
      _isFullLockActive = true;
      print('🔒 Break ended - Full focus lock re-activated');
    } else {
      await PhoneLockService.enableLock();
      print('🔒 Break ended - Focus lock re-activated');
    }

    await _saveLockState();
  }

  static Future<void> endBreak() async {
    _isInBreak = false;
    _breakWarningTriggered = false;
    _breakEndTime = null;

    _breakTimer?.cancel();
    _breakTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;

    // Re-lock when break ends
    if (_isLocked) {
      await PhoneLockService.enableFullLock();
      _isFullLockActive = true;
      print('🔒 Break ended - Full focus lock re-activated');
    } else {
      await PhoneLockService.enableLock();
      print('🔒 Break ended - Focus lock re-activated');
    }

    await _saveLockState();
  }

  // ─── USER RETURN HANDLER ───

  static void handleUserReturned() {
    print('✅ User returned to app');

    // Clear warning state
    _breakWarningTriggered = false;

    // If we're in break and lock is active, re-lock
    if (!_isInBreak && _isLocked) {
      if (_isFullLockActive) {
        PhoneLockService.enableFullLock();
      } else {
        PhoneLockService.enableLock();
      }
    }
  }

  // ─── BACKGROUND CHECKING ───

  static Future<bool> checkBreakStatusOnResume() async {
    if (_isInBreak && _breakEndTime != null) {
      final now = DateTime.now();
      if (now.isAfter(_breakEndTime!)) {
        print('⏰ Break should have ended while in background');
        await _onBreakEnded();
        return true;
      }

      // Check if warning should have been triggered
      final warningTime = _breakEndTime!.subtract(const Duration(seconds: 10));
      if (now.isAfter(warningTime) && !_breakWarningTriggered) {
        print('⏰ Break warning should have triggered while in background');
        await _triggerBreakWarning();
        return true;
      }
    }
    return false;
  }

  // ─── PERSISTENCE ───

  static Future<void> _saveLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'isLocked': _isLocked,
        'isInBreak': _isInBreak,
        'lockDurationMinutes': _lockDurationMinutes,
        'breakEndTime': _breakEndTime?.millisecondsSinceEpoch,
        'isFullLockActive': _isFullLockActive,
      };
      // FIXED: Use jsonEncode instead of toString()
      await prefs.setString('focus_lock_state', jsonEncode(state));
    } catch (e) {
      print('Error saving lock state: $e');
    }
  }

  static Future<void> _clearLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('focus_lock_state');
    } catch (e) {
      print('Error clearing lock state: $e');
    }
  }

  static Future<Map<String, dynamic>?> _getLockState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateString = prefs.getString('focus_lock_state');
      if (stateString != null) {
        // FIXED: Use jsonDecode instead of manual parsing
        return jsonDecode(stateString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting lock state: $e');
      return null;
    }
  }

  // ─── RESET ───

  static Future<void> reset() async {
    _isLocked = false;
    _isInBreak = false;
    _breakWarningTriggered = false;
    _lockDurationMinutes = 0;
    _onLockViolated = null;
    _breakEndTime = null;

    _breakTimer?.cancel();
    _breakTimer = null;
    _warningTimer?.cancel();
    _warningTimer = null;

    if (_isFullLockActive) {
      await PhoneLockService.disableFullLock();
      _isFullLockActive = false;
    } else {
      await PhoneLockService.disableLock();
    }

    await ForcedReturnService.reset();
    await _clearLockState();
    print('🔄 FocusLockService reset');
  }

  // ─── STATUS CHECKING ───

  static String getStatus() {
    if (_isLocked && !_isInBreak) {
      return _isFullLockActive ? '🔒 Full Lock - Study Mode' : '🔒 Locked - Study Mode';
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

  // FIXED: This was conflicting - renamed to getIsFullLockActive
  static bool getIsFullLockActive() => _isFullLockActive;

  static int getRemainingBreakSeconds() {
    if (_breakEndTime == null) return 0;
    final remaining = _breakEndTime!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  static bool isBreakWarningTriggered() => _breakWarningTriggered;

  // ─── EXTRA UTILITY METHODS ───

  static Future<void> toggleFullLock() async {
    if (_isFullLockActive) {
      await PhoneLockService.disableFullLock();
      _isFullLockActive = false;
    } else {
      await PhoneLockService.enableFullLock();
      _isFullLockActive = true;
    }
    await _saveLockState();
  }

  static Future<void> restoreLockState() async {
    try {
      final state = await _getLockState();
      if (state != null) {
        _isLocked = state['isLocked'] ?? false;
        _isInBreak = state['isInBreak'] ?? false;
        _lockDurationMinutes = state['lockDurationMinutes'] ?? 0;
        _isFullLockActive = state['isFullLockActive'] ?? false;

        if (_isInBreak && state['breakEndTime'] != null) {
          _breakEndTime = DateTime.fromMillisecondsSinceEpoch(state['breakEndTime']);
        }

        // Restore lock if needed
        if (_isLocked && !_isInBreak) {
          if (_isFullLockActive) {
            await PhoneLockService.enableFullLock();
          } else {
            await PhoneLockService.enableLock();
          }
        }

        print('🔄 FocusLockService state restored');
      }
    } catch (e) {
      print('Error restoring lock state: $e');
    }
  }
}