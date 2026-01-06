import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../constants/app_constants.dart';

/// Service responsible for lazy initialization of Firebase projects.
/// Only initializes Firebase when a specific school is selected.
class FirebaseInitializationService {
  // Track which Firebase apps have been initialized
  static final Set<String> _initializedApps = <String>{};

  /// Initializes Firebase for a specific school if not already initialized.
  /// 
  /// Returns the FirebaseApp instance for the school.
  /// Throws [FirebaseInitializationException] if initialization fails.
  static Future<FirebaseApp> initializeForSchool(String schoolCode) async {
    // Validate school code
    if (!AppConstants.isValidSchoolCode(schoolCode)) {
      throw FirebaseInitializationException(
        'Invalid school code: $schoolCode. Valid codes are: ${AppConstants.validSchoolCodes.join(", ")}',
      );
    }

    final String appName = _getAppName(schoolCode);
    
    // Check if already initialized
    if (_initializedApps.contains(appName)) {
      if (kDebugMode) {
      debugPrint('✅ Firebase already initialized for School $schoolCode (App: $appName)');
    }
      try {
        return Firebase.app(appName);
      } catch (e) {
        // App name exists but app might have been deleted, reinitialize
        _initializedApps.remove(appName);
      }
    }

    try {
      // Get the appropriate Firebase options
      final FirebaseOptions options = _getFirebaseOptions(schoolCode);
      
 if (kDebugMode) {
      debugPrint('🔥 Initializing Firebase for School $schoolCode...');
      debugPrint('   Project ID: ${options.projectId}');
      debugPrint('   App Name: $appName');

    }



      // Initialize Firebase for this school
      final FirebaseApp app = await Firebase.initializeApp(
        name: appName,
        options: options,
      );
      
      _initializedApps.add(appName);
      if (kDebugMode) {
      debugPrint('✅ Firebase initialized for School $schoolCode ');
      debugPrint('   Firebase App: ${app.name}');
    }
      return app;
    } catch (e) {
      if (kDebugMode) {
      debugPrint('❌ Failed to initialize Firebase for School $schoolCode: $e');
    }
      throw FirebaseInitializationException(
        'Failed to initialize Firebase for school $schoolCode: $e',
      );
    }
  }

  /// Checks if Firebase is initialized for a specific school.
  static bool isInitialized(String schoolCode) {
    if (!AppConstants.isValidSchoolCode(schoolCode)) {
      return false;
    }
    return _initializedApps.contains(_getAppName(schoolCode));
  }

  /// Gets the FirebaseApp instance for a school.
  /// Throws if not initialized.
  static FirebaseApp getApp(String schoolCode) {
    if (!AppConstants.isValidSchoolCode(schoolCode)) {
      throw FirebaseInitializationException(
        'Invalid school code: $schoolCode',
      );
    }

    final String appName = _getAppName(schoolCode);
    
    if (!_initializedApps.contains(appName)) {
      throw FirebaseInitializationException(
        'Firebase not initialized for school $schoolCode. '
        'Call initializeForSchool() first.',
      );
    }
    
    try {
      return Firebase.app(appName);
    } catch (e) {
      throw FirebaseInitializationException(
        'Firebase app not found for school $schoolCode: $e',
      );
    }
  }

  /// Gets the app name for a school code.
  static String _getAppName(String schoolCode) {
    switch (schoolCode.toUpperCase()) {
      case AppConstants.schoolCodeA:
        return AppConstants.firebaseAppNameA;
      case AppConstants.schoolCodeB:
        return AppConstants.firebaseAppNameB;
      case AppConstants.schoolCodeC:
        return AppConstants.firebaseAppNameC;
      default:
        throw ArgumentError('Invalid school code: $schoolCode');
    }
  }

  /// Gets Firebase options for a school code.
  static FirebaseOptions _getFirebaseOptions(String schoolCode) {
    switch (schoolCode.toUpperCase()) {
      case AppConstants.schoolCodeA:
        return SchoolFirebaseOptions.schoolA;
      case AppConstants.schoolCodeB:
        return SchoolFirebaseOptions.schoolB;
      case AppConstants.schoolCodeC:
        return SchoolFirebaseOptions.schoolC;
      default:
        throw ArgumentError('Invalid school code: $schoolCode');
    }
  }

  /// Clears all initialized apps (useful for testing or logout).
  static void clearAll() {
    _initializedApps.clear();
  }

  /// Gets list of all initialized school codes.
  static List<String> getInitializedSchools() {
    final List<String> schools = [];
    if (_initializedApps.contains(AppConstants.firebaseAppNameA)) {
      schools.add(AppConstants.schoolCodeA);
    }
    if (_initializedApps.contains(AppConstants.firebaseAppNameB)) {
      schools.add(AppConstants.schoolCodeB);
    }
    if (_initializedApps.contains(AppConstants.firebaseAppNameC)) {
      schools.add(AppConstants.schoolCodeC);
    }
    return schools;
  }
}

/// Exception thrown when Firebase initialization fails.
class FirebaseInitializationException implements Exception {
  final String message;
  
  FirebaseInitializationException(this.message);
  
  @override
  String toString() => 'FirebaseInitializationException: $message';
}

