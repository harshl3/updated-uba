import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_initialization_service.dart';

/// Utility class for getting Firebase app instances for schools.
/// Ensures Firebase is initialized before returning the app.
class SchoolSelector {
  /// Gets the FirebaseApp instance for a school.
  /// Automatically initializes Firebase if not already initialized.
  static Future<FirebaseApp> getApp(String schoolCode) async {
    if (!FirebaseInitializationService.isInitialized(schoolCode)) {
      return await FirebaseInitializationService.initializeForSchool(schoolCode);
    }
    return FirebaseInitializationService.getApp(schoolCode);
  }

  /// Synchronously gets the FirebaseApp instance (throws if not initialized).
  /// Use this only when you're certain Firebase is already initialized.
  static FirebaseApp getAppSync(String schoolCode) {
    return FirebaseInitializationService.getApp(schoolCode);
  }
}
