import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceHelpers {
  static Future<String> getUniqueHardwareId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isIOS) {
        // In Iphone identifierForVendor
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown_ios_id';
      } else if (Platform.isAndroid) {
        // In Android we use the device id
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Device ID for Android
      }
    } catch (e) {
      return 'unknown_device_id';
    }

    return 'unsupported_platform';
  }
}
