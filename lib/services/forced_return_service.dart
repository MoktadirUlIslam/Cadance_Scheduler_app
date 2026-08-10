// lib/services/forced_return_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ForcedReturnService {
  static const MethodChannel _channel = MethodChannel('forced_return');
  static bool _isShowing = false;
  static VoidCallback? _onUserReturnedCallback;
  static bool _isInitialized = false;
  static bool _notificationsEnabled = true;
  static bool _isDismissing = false;
  static bool _isHandlingReturn = false;

  // ─── NEW: Track if app is in foreground ───
  static bool _isAppInForeground = true;

  static void initialize() {
    if (_isInitialized) return;

    _channel.setMethodCallHandler(_handleMethodCall);
    _isInitialized = true;
    print('✅ ForcedReturnService initialized');
  }

  // ─── NEW: Set app foreground state ───
  static void setAppInForeground(bool inForeground) {
    _isAppInForeground = inForeground;
    print('📱 App foreground state: $_isAppInForeground');
  }

  // ─── NEW: Check if app is in foreground ───
  static bool isAppInForeground() {
    return _isAppInForeground;
  }

  static void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    print('🔔 Notifications enabled: $_notificationsEnabled');
  }

  static bool areNotificationsEnabled() {
    return _notificationsEnabled;
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'userReturnedToApp':
        print('📱 Native: User returned to app');
        _isAppInForeground = true; // ─── NEW: Set foreground ───
        await _handleUserReturned();
        return true;
      default:
        throw PlatformException(
          code: 'NOT_IMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  static Future<bool> showForcedReturn({
    required String title,
    required String subtitle,
    int countdown = 10,
    bool playAlarm = true,
  }) async {
    if (!_notificationsEnabled) {
      print('⚠️ Notifications disabled - Forced return overlay SKIPPED');
      return false;
    }

    // ─── NEW: Don't show overlay if app is in foreground ───
    if (_isAppInForeground) {
      print('⚠️ App is in foreground - Skipping overlay (already in app)');
      // Show a simple dialog instead
      await _showInAppWarning(title, subtitle, countdown);
      return false;
    }

    if (_isShowing) {
      print('⚠️ Overlay already showing');
      return false;
    }

    try {
      final result = await _channel.invokeMethod('showForcedReturn', {
        'title': title,
        'subtitle': subtitle,
        'countdown': countdown,
        'alarmSound': playAlarm,
      });

      _isShowing = result == true;
      _isDismissing = false;
      _isHandlingReturn = false;
      print('✅ Forced return overlay shown: $_isShowing');
      return _isShowing;

    } on PlatformException catch (e) {
      print('❌ Failed to show overlay: ${e.message}');
      _isShowing = false;
      await _showFallbackDialog(title, subtitle, countdown);
      return false;
    }
  }

  // ─── NEW: Show in-app warning instead of overlay ───
  static Future<void> _showInAppWarning(String title, String subtitle, int countdown) async {
    print('📱 Showing in-app warning (user already in app)');

    final context = _getGlobalContext();
    if (context == null) {
      print('❌ No context available for in-app warning');
      return;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.alarm, color: Colors.orange, size: 28),
              const SizedBox(width: 8),
              Text(title.replaceAll('⚠️', '⏰')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(subtitle),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  countdown.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'seconds remaining in break',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              const Text(
                'You are already in the app! Stay focused! 💪',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('✅ I\'m Focused!'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('❌ In-app warning error: $e');
    }
  }

  static Future<bool> dismissForcedReturn({bool force = false}) async {
    if (_isDismissing && !force) {
      print('⚠️ Already dismissing overlay');
      return true;
    }

    if (!_isShowing && !force) {
      print('⚠️ Overlay not showing, nothing to dismiss');
      return true;
    }

    _isDismissing = true;

    try {
      final result = await _channel.invokeMethod('dismissForcedReturn');
      _isShowing = false;
      _isDismissing = false;
      _isHandlingReturn = false;
      print('✅ Forced return overlay dismissed: $result');
      return result == true;

    } on PlatformException catch (e) {
      print('❌ Failed to dismiss overlay: ${e.message}');
      _isDismissing = false;
      _isShowing = false;
      return false;
    }
  }

  static Future<bool> isOverlayShowing() async {
    try {
      final result = await _channel.invokeMethod('isOverlayShowing');
      _isShowing = result == true;
      return _isShowing;
    } catch (e) {
      return _isShowing;
    }
  }

  static void setOnUserReturned(VoidCallback? callback) {
    _onUserReturnedCallback = callback;
    print('✅ User returned callback ${callback != null ? 'set' : 'cleared'}');
  }

  static Future<void> forceDismissOverlay() async {
    if (_isHandlingReturn) {
      print('⚠️ Already handling return, skipping force dismiss');
      return;
    }

    print('🔄 Force dismissing overlay...');
    _isHandlingReturn = true;

    try {
      await dismissForcedReturn(force: true);
    } catch (e) {
      print('⚠️ Force dismiss error: $e');
    }

    _isShowing = false;
    _isDismissing = false;
    _isHandlingReturn = false;
    _isAppInForeground = true; // ─── NEW: Set foreground ───
    print('✅ Force dismiss complete');
  }

  static Future<void> _handleUserReturned() async {
    if (_isHandlingReturn) {
      print('⚠️ Already handling return, ignoring duplicate');
      return;
    }

    print('✅ User returned callback triggered');
    _isHandlingReturn = true;
    _isAppInForeground = true; // ─── NEW: Set foreground ───

    await forceDismissOverlay();
    await _clearForcedReturnState();

    if (_onUserReturnedCallback != null) {
      _onUserReturnedCallback!();
    }

    _isHandlingReturn = false;
    print('✅ User return handled successfully');
  }

  static Future<void> _clearForcedReturnState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('forced_return_active');
      await prefs.remove('forced_return_break_end');
      print('✅ Forced return state cleared');
    } catch (e) {
      print('⚠️ Failed to clear state: $e');
    }
  }

  static Future<void> _saveForcedReturnState(bool active) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('forced_return_active', active);
      if (active) {
        await prefs.setInt(
          'forced_return_timestamp',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {
      print('⚠️ Failed to save state: $e');
    }
  }

  static Future<void> _showFallbackDialog(
      String title,
      String subtitle,
      int countdown,
      ) async {
    if (!_notificationsEnabled) {
      print('⚠️ Notifications disabled - Fallback dialog SKIPPED');
      return;
    }

    final context = _getGlobalContext();
    if (context == null) {
      print('❌ No context available for fallback dialog');
      return;
    }

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 28),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    countdown.toString(),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'seconds remaining',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '⚠️ You cannot dismiss this dialog',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _handleUserReturned();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('🔒 RETURN TO APP'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('❌ Fallback dialog error: $e');
    }
  }

  static BuildContext? _getGlobalContext() {
    try {
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> checkBreakStatusOnResume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool('forced_return_active') ?? false;
      final breakEndTime = prefs.getInt('forced_return_break_end');

      if (isActive && breakEndTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now > breakEndTime) {
          print('⚠️ Break is over, user hasn\'t returned');
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> triggerBreakWarningOnResume() async {
    if (!_notificationsEnabled) {
      print('⚠️ Notifications disabled - Break warning SKIPPED');
      return;
    }

    final needsWarning = await checkBreakStatusOnResume();
    if (needsWarning) {
      print('⚠️ Break overdue! Triggering warning...');
      await showForcedReturn(
        title: '⚠️ BREAK OVERDUE!',
        subtitle: 'Return to app immediately!',
        countdown: 5,
        playAlarm: true,
      );
    }
  }

  static Future<void> reset() async {
    await forceDismissOverlay();
    _isShowing = false;
    _onUserReturnedCallback = null;
    _isDismissing = false;
    _isHandlingReturn = false;
    _isAppInForeground = true; // ─── NEW: Set foreground ───
    await _clearForcedReturnState();
    print('✅ ForcedReturnService reset');
  }

  static Future<void> emergencyReset() async {
    print('🚨 EMERGENCY RESET - Forcing overlay dismiss');
    _isShowing = false;
    _isDismissing = false;
    _isHandlingReturn = false;
    _isAppInForeground = true;
    try {
      await _channel.invokeMethod('dismissForcedReturn');
    } catch (e) {
      print('⚠️ Emergency reset error: $e');
    }
    await _clearForcedReturnState();
  }
}