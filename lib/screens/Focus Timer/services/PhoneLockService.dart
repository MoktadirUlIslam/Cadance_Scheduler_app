// lib/services/phone_lock_service.dart
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io' show Platform;

class PhoneLockService {
  static const MethodChannel _channel = MethodChannel('phone_lock');

  static bool _isFullLockActive = false;
  static bool _isLockSupported = false;
  static bool _isInitialized = false;

  /// Initialize the service and check support
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isLockSupported = await _checkLockSupport();
      _isInitialized = true;
      print('✅ PhoneLockService initialized. Lock supported: $_isLockSupported');
    } catch (e) {
      print('❌ PhoneLockService initialization error: $e');
      // Default to true on Android, false on iOS
      _isLockSupported = Platform.isAndroid;
      _isInitialized = true;
    }
  }

  /// Check if lock is supported on this device
  static Future<bool> _checkLockSupport() async {
    try {
      // Try a simple method that should exist
      final result = await _channel.invokeMethod('isLockSupported');
      return result == true;
    } catch (e) {
      // If method doesn't exist, assume Android supports it
      if (Platform.isAndroid) {
        print('⚠️ isLockSupported method not found, assuming Android supports lock');
        return true;
      }
      return false;
    }
  }

  /// Check if lock is supported (public method)
  static Future<bool> isLockSupported() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isLockSupported;
  }

  /// Enable full lock (App Pinning + Fullscreen + No Navigation + No Power Off)
  static Future<bool> enableFullLock() async {
    if (!_isLockSupported && Platform.isAndroid) {
      print('⚠️ Full lock not supported on this device');
      // Try anyway since we're on Android
    }

    if (_isFullLockActive) {
      print('⚠️ Full lock already active');
      return true;
    }

    try {
      final result = await _channel.invokeMethod('enableFullLock');
      _isFullLockActive = true;

      // Set full lock state
      try {
        await _channel.invokeMethod('setFullLockState', {'active': true});
      } catch (e) {
        // Ignore - method might not exist
      }

      print('🔒 Full lock enabled');
      return result == true;
    } catch (e) {
      print('❌ enableFullLock error: $e');
      // Try fallback
      return await _enableFullLockFallback();
    }
  }

  /// Fallback method for enabling full lock
  static Future<bool> _enableFullLockFallback() async {
    try {
      // Try each method individually
      bool success = true;

      try {
        final result = await _channel.invokeMethod('enableLock');
        success = success && (result == true);
      } catch (e) {
        print('❌ enableLock fallback failed: $e');
        success = false;
      }

      try {
        await _channel.invokeMethod('enableFullScreenLock');
      } catch (e) {
        print('❌ enableFullScreenLock fallback failed: $e');
      }

      try {
        await _channel.invokeMethod('preventPowerOff', {'prevent': true});
      } catch (e) {
        print('❌ preventPowerOff fallback failed: $e');
      }

      _isFullLockActive = success;
      return success;
    } catch (e) {
      print('❌ Full lock fallback failed: $e');
      return false;
    }
  }

  /// Disable full lock
  static Future<bool> disableFullLock() async {
    if (!_isFullLockActive) {
      print('⚠️ Full lock already disabled');
      return true;
    }

    try {
      final result = await _channel.invokeMethod('disableFullLock');
      _isFullLockActive = false;

      try {
        await _channel.invokeMethod('setFullLockState', {'active': false});
      } catch (e) {
        // Ignore - method might not exist
      }

      print('🔓 Full lock disabled');
      return result == true;
    } catch (e) {
      print('❌ disableFullLock error: $e');
      // Try fallback
      return await _disableFullLockFallback();
    }
  }

  /// Fallback method for disabling full lock
  static Future<bool> _disableFullLockFallback() async {
    try {
      bool success = true;

      try {
        final result = await _channel.invokeMethod('disableLock');
        success = success && (result == true);
      } catch (e) {
        print('❌ disableLock fallback failed: $e');
        success = false;
      }

      try {
        await _channel.invokeMethod('disableFullScreenLock');
      } catch (e) {
        print('❌ disableFullScreenLock fallback failed: $e');
      }

      try {
        await _channel.invokeMethod('preventPowerOff', {'prevent': false});
      } catch (e) {
        print('❌ preventPowerOff fallback failed: $e');
      }

      _isFullLockActive = false;
      return success;
    } catch (e) {
      print('❌ Full lock fallback failed: $e');
      return false;
    }
  }

  /// Enable app pinning only
  static Future<bool> enableLock() async {
    if (!_isLockSupported && Platform.isAndroid) {
      print('⚠️ Lock not supported on this device');
      // Try anyway
    }

    try {
      final result = await _channel.invokeMethod('enableLock');
      print('🔒 App pinning enabled');
      return result == true;
    } catch (e) {
      print('❌ enableLock error: $e');
      return false;
    }
  }

  /// Disable app pinning only
  static Future<bool> disableLock() async {
    if (!_isLockSupported && Platform.isAndroid) {
      print('⚠️ Lock not supported on this device');
      return true;
    }

    try {
      final result = await _channel.invokeMethod('disableLock');
      print('🔓 App pinning disabled');
      return result == true;
    } catch (e) {
      print('❌ disableLock error: $e');
      return false;
    }
  }

  /// Check if locked (app pinning active)
  static Future<bool> isLocked() async {
    if (!_isLockSupported) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod('isLocked');
      return result == true;
    } catch (e) {
      print('❌ isLocked error: $e');
      return false;
    }
  }

  /// Check if full lock is active
  static bool get isFullLockActive => _isFullLockActive;

  /// Get full lock state from native
  static Future<bool> getFullLockState() async {
    try {
      final result = await _channel.invokeMethod('isFullLockActive');
      _isFullLockActive = result == true;
      return _isFullLockActive;
    } catch (e) {
      return _isFullLockActive;
    }
  }

  /// Toggle full lock state
  static Future<bool> toggleFullLock() async {
    if (_isFullLockActive) {
      return await disableFullLock();
    } else {
      return await enableFullLock();
    }
  }

  /// Reset lock state (disable everything)
  static Future<void> reset() async {
    try {
      // Try full lock disable first
      if (_isFullLockActive) {
        await disableFullLock();
      }

      // Try to disable everything
      try {
        await _channel.invokeMethod('disableLock');
      } catch (e) {
        // Ignore
      }

      try {
        await _channel.invokeMethod('disableFullScreenLock');
      } catch (e) {
        // Ignore
      }

      try {
        await _channel.invokeMethod('preventPowerOff', {'prevent': false});
      } catch (e) {
        // Ignore
      }

      _isFullLockActive = false;
      print('🔄 PhoneLockService reset');
    } catch (e) {
      print('❌ reset error: $e');
    }
  }

  /// Check if power off is prevented
  static Future<bool> isPowerOffPrevented() async {
    try {
      final result = await _channel.invokeMethod('isPowerOffPrevented');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// Prevent system UI interactions
  static Future<void> blockSystemUI() async {
    try {
      await _channel.invokeMethod('enableFullScreenLock');
      print('✅ System UI blocked');
    } catch (e) {
      print('❌ blockSystemUI error: $e');
    }
  }

  /// Restore system UI interactions
  static Future<void> restoreSystemUI() async {
    try {
      await _channel.invokeMethod('disableFullScreenLock');
      print('✅ System UI restored');
    } catch (e) {
      print('❌ restoreSystemUI error: $e');
    }
  }

  /// Enable full screen mode
  static Future<bool> enableFullScreen() async {
    try {
      final result = await _channel.invokeMethod('enableFullScreenLock');
      return result == true;
    } catch (e) {
      print('❌ enableFullScreen error: $e');
      return false;
    }
  }

  /// Disable full screen mode
  static Future<bool> disableFullScreen() async {
    try {
      final result = await _channel.invokeMethod('disableFullScreenLock');
      return result == true;
    } catch (e) {
      print('❌ disableFullScreen error: $e');
      return false;
    }
  }

  /// Prevent power off
  static Future<bool> preventPowerOff(bool prevent) async {
    try {
      final result = await _channel.invokeMethod('preventPowerOff', {'prevent': prevent});
      return result == true;
    } catch (e) {
      print('❌ preventPowerOff error: $e');
      return false;
    }
  }

  /// Get lock status as string
  static Future<String> getLockStatus() async {
    final locked = await isLocked();
    final fullLock = _isFullLockActive;

    if (fullLock) {
      return '🔒 Full Lock Active';
    } else if (locked) {
      return '🔒 App Pinning Active';
    } else {
      return '🔓 Unlocked';
    }
  }

  /// Check if app is in foreground (for platform-specific checks)
  static Future<bool> isAppInForeground() async {
    try {
      final result = await _channel.invokeMethod('isAppInForeground');
      return result == true;
    } catch (e) {
      return true; // Assume foreground if can't determine
    }
  }

  /// Bring app to foreground
  static Future<bool> bringAppToForeground() async {
    try {
      final result = await _channel.invokeMethod('bringAppToForeground');
      return result == true;
    } catch (e) {
      print('❌ bringAppToForeground error: $e');
      return false;
    }
  }

  // ─── DEVICE CAPABILITIES ───

  /// Check if device has app pinning capability
  static bool hasAppPinningCapability() {
    return Platform.isAndroid;
  }

  /// Check if device has full screen capability
  static bool hasFullScreenCapability() {
    return true; // Most devices support full screen
  }

  /// Check if device has power prevention capability
  static bool hasPowerPreventionCapability() {
    return Platform.isAndroid;
  }

  // ─── STATUS REPORTING ───

  /// Get detailed status report
  static Future<Map<String, dynamic>> getStatusReport() async {
    return {
      'isLockSupported': _isLockSupported,
      'isLocked': await isLocked(),
      'isFullLockActive': _isFullLockActive,
      'isPowerOffPrevented': await isPowerOffPrevented(),
      'status': await getLockStatus(),
      'hasAppPinning': hasAppPinningCapability(),
      'hasFullScreen': hasFullScreenCapability(),
      'hasPowerPrevention': hasPowerPreventionCapability(),
      'platform': Platform.operatingSystem,
    };
  }
}