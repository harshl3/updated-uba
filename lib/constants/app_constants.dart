/// Application-wide constants
class AppConstants {
  AppConstants._(); // Private constructor to prevent instantiation

  // School codes
  static const String schoolCodeA = 'A';
  static const String schoolCodeB = 'B';
  static const String schoolCodeC = 'C';

  // School names
  static const String schoolNameA = 'School A';
  static const String schoolNameB = 'School B';
  static const String schoolNameC = 'School C';

  // Roles
  static const String roleStudent = 'student';
  static const String roleTeacher = 'teacher';

  // Firebase app names
  static const String firebaseAppNameA = 'schoolA';
  static const String firebaseAppNameB = 'schoolB';
  static const String firebaseAppNameC = 'schoolC';

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 600);
  
  // Snackbar durations
  static const Duration snackbarDurationShort = Duration(seconds: 2);
  static const Duration snackbarDurationLong = Duration(seconds: 3);

  // Valid school codes
  static const List<String> validSchoolCodes = [schoolCodeA, schoolCodeB, schoolCodeC];

  /// Checks if a school code is valid
  static bool isValidSchoolCode(String code) {
    return validSchoolCodes.contains(code.toUpperCase());
  }

  /// Gets teacher email for a school code
  /// Fixed teacher credentials per school - NO SIGNUP ALLOWED
  static String getTeacherEmail(String schoolCode) {
    switch (schoolCode.toUpperCase()) {
      case schoolCodeA:
        return 'schoola@gmail.com';
      case schoolCodeB:
        return 'schoolb@gmail.com';
      case schoolCodeC:
        return 'schoolc@gmail.com';
      default:
        throw ArgumentError('Invalid school code: $schoolCode');
    }
  }

  /// Gets teacher password for a school code
  /// Fixed teacher credentials per school - NO SIGNUP ALLOWED
  static String getTeacherPassword(String schoolCode) {
    switch (schoolCode.toUpperCase()) {
      case schoolCodeA:
        return 'schoola123';
      case schoolCodeB:
        return 'schoolb123';
      case schoolCodeC:
        return 'schoolc123';
      default:
        throw ArgumentError('Invalid school code: $schoolCode');
    }
  }

  /// Validates if an email matches the teacher email for a school
  static bool isTeacherEmail(String email, String schoolCode) {
    return email.toLowerCase() == getTeacherEmail(schoolCode).toLowerCase();
  }
}




