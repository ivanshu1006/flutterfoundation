import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../services/logger_service.dart';

class Utils {
  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  static Future<String?> getSid() {
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    return secureStorage.read(key: 'sid');
  }

  static Future<bool> checkAuthentication() async {
    const FlutterSecureStorage secureStorage = FlutterSecureStorage();
    final sid = await secureStorage.read(key: 'sid');
    final sidExpiry = await secureStorage.read(key: 'sidExpiry');

    logger.info('Checking authentication');
    logger.info('sid: $sid');
    logger.info('sidExpiry: $sidExpiry');

    // Check if both sid and sidExpiry are not null
    if (sid != null && sidExpiry != null) {
      // Convert sidExpiry to DateTime
      final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz');
      final expiryDateTime = formatter.parse(sidExpiry);

      // Check if the sidExpiry is in the future
      if (expiryDateTime.isAfter(DateTime.now())) {
        logger.info('User is logged in');
        return true; // User is logged in
      }
    }
    logger.info('User is not logged in');
    return false; // User is not logged in
  }
}
