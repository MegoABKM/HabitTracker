import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Handler for Android-specific permissions
class PermissionHandler {
  static const MethodChannel _channel = MethodChannel(
    'com.habit_tracker/permissions',
  );

  /// Request overlay permission
  static Future<bool> requestOverlayPermission() async {
    try {
      final bool result = await _channel.invokeMethod(
        'requestOverlayPermission',
      );
      return result;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

  /// Check if overlay permission is granted
  static Future<bool> isOverlayPermissionGranted() async {
    try {
      final bool result = await _channel.invokeMethod(
        'isOverlayPermissionGranted',
      );
      return result;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request to ignore battery optimization
  static Future<void> requestIgnoreBatteryOptimization() async {
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (e) {
      print('Error requesting battery optimization: $e');
    }
  }

  /// Check if battery optimization is ignored
  static Future<bool> isIgnoringBatteryOptimization() async {
    try {
      final bool result = await _channel.invokeMethod(
        'isIgnoringBatteryOptimization',
      );
      return result;
    } catch (e) {
      print('Error checking battery optimization: $e');
      return false;
    }
  }

  /// Show dialog to request permissions
  static Future<void> requestAllPermissions() async {
    final overlayGranted = await isOverlayPermissionGranted();
    final batteryIgnored = await isIgnoringBatteryOptimization();

    if (!overlayGranted || !batteryIgnored) {
      await Get.dialog(
        AlertDialog(
          title: const Text('Permissions Required'),
          content: Text('''
This app needs the following permissions to track time in the background:

${!overlayGranted ? '• Display over other apps\n' : ''}
${!batteryIgnored ? '• Battery optimization exemption\n' : ''}
Please grant these permissions for best experience.
            '''),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Get.back();
                if (!overlayGranted) await requestOverlayPermission();
                if (!batteryIgnored) await requestIgnoreBatteryOptimization();
              },
              child: const Text('Grant Permissions'),
            ),
          ],
        ),
      );
    }
  }
}
