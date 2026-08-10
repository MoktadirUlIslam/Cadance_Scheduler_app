// lib/services/phone_lock_service.dart
import 'package:flutter/services.dart';

class PhoneLockService {
  static const MethodChannel _channel = MethodChannel('phone_lock');

  /// Enable phone lock (App Pinning)
  static Future<bool> enableLock() async {
    try {
      final result = await _channel.invokeMethod('enableLock');
      return result == true;
    } catch (e) {
      print('❌ enableLock error: $e');
      return false;
    }
  }

  /// Disable phone lock (Release App Pinning)
  static Future<bool> disableLock() async {
    try {
      final result = await _channel.invokeMethod('disableLock');
      return result == true;
    } catch (e) {
      print('❌ disableLock error: $e');
      return false;
    }
  }

  /// Check if phone is currently locked (App Pinning active)
  static Future<bool> isLocked() async {
    try {
      final result = await _channel.invokeMethod('isLocked');
      return result == true;
    } catch (e) {
      print('❌ isLocked error: $e');
      return false;
    }
  }

  /// Toggle lock state (Enable if disabled, disable if enabled)
  static Future<bool> toggleLock() async {
    final bool currentlyLocked = await isLocked();
    if (currentlyLocked) {
      return await disableLock();
    } else {
      return await enableLock();
    }
  }

  /// Get lock status as string
  static Future<String> getLockStatus() async {
    final bool locked = await isLocked();
    return locked ? '🔒 Locked' : '🔓 Unlocked';
  }

  /// Enable lock with safety check
  static Future<bool> enableLockSafe() async {
    try {
      // Check if already locked
      if (await isLocked()) {
        print('⚠️ Already locked');
        return true;
      }
      return await enableLock();
    } catch (e) {
      print('❌ enableLockSafe error: $e');
      return false;
    }
  }

  /// Disable lock with safety check
  static Future<bool> disableLockSafe() async {
    try {
      // Check if already unlocked
      if (!await isLocked()) {
        print('⚠️ Already unlocked');
        return true;
      }
      return await disableLock();
    } catch (e) {
      print('❌ disableLockSafe error: $e');
      return false;
    }
  }

  /// Force disable lock (no safety check)
  static Future<void> forceDisableLock() async {
    try {
      await _channel.invokeMethod('disableLock');
      print('🔓 Force disabled lock');
    } catch (e) {
      print('❌ forceDisableLock error: $e');
    }
  }

  /// Force enable lock (no safety check)
  static Future<void> forceEnableLock() async {
    try {
      await _channel.invokeMethod('enableLock');
      print('🔒 Force enabled lock');
    } catch (e) {
      print('❌ forceEnableLock error: $e');
    }
  }

  /// Check if lock is supported on this device
  static Future<bool> isLockSupported() async {
    try {
      // Try to call a method that only exists on Android
      // This is a simple check, you can make it more robust
      final result = await _channel.invokeMethod('isLockSupported');
      return result == true;
    } catch (e) {
      // If method doesn't exist, assume not supported
      return false;
    }
  }
}