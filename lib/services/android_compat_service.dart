import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_api_availability/google_api_availability.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle Android-specific compatibility and OEM behaviors
class AndroidCompatService {
  static final AndroidCompatService _instance = AndroidCompatService._internal();
  factory AndroidCompatService() => _instance;
  AndroidCompatService._internal();

  /// Check if Google Mobile Services (GMS) are available
  /// Essential for Huawei (HMS only) devices
  Future<bool> isGmsAvailable() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final googlePlayServicesAvailability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
      return googlePlayServicesAvailability == GooglePlayServicesAvailability.success;
    } catch (e) {
      debugPrint('❌ Error checking GMS availability: $e');
      return false;
    }
  }

  /// Check if the app is being ignores for battery optimizations
  /// Relevant for aggressive OEM power managers (Xiaomi, Oppo, Vivo)
  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!Platform.isAndroid) return true;
    
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking battery optimizations: $e');
      return true;
    }
  }

  /// Request to ignore battery optimizations
  /// Use this only when absolutely necessary (e.g. for mission critical notifications)
  Future<void> requestIgnoreBatteryOptimizations() async {
    if (!Platform.isAndroid) return;
    await Permission.ignoreBatteryOptimizations.request();
  }

  /// Check and request notification permissions (Android 13+)
  Future<bool> checkNotificationPermission() async {
    if (!Platform.isAndroid) return true;
    
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  /// Detect OEM Brand for targeted debugging or behavior adjustments
  String getDeviceBrand() {
    if (!Platform.isAndroid) return 'unknown';
    // This is a placeholder; in a real app you might use device_info_plus
    return 'android';
  }
}
