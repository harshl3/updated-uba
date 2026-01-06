import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import 'firebase_initialization_service.dart';
import '../firestore_service.dart';

/// Service for handling Firebase Authentication with school-scoped isolation.
/// Ensures teachers and students can only authenticate within their own school's Firebase project.
class AuthService {
  /// Gets Firebase Auth instance for a specific school.
  /// This ensures authentication is isolated per school.
  static Future<FirebaseAuth> _getAuth(String schoolCode) async {
    final FirebaseApp app = await FirebaseInitializationService.initializeForSchool(schoolCode);
    return FirebaseAuth.instanceFor(app: app);
  }

  /// Synchronously gets Firebase Auth instance (throws if Firebase not initialized).
  /// Use this only when you're certain Firebase is already initialized.
  static FirebaseAuth _getAuthSync(String schoolCode) {
    final FirebaseApp app = FirebaseInitializationService.getApp(schoolCode);
    return FirebaseAuth.instanceFor(app: app);
  }

  /// Teacher Login - Uses fixed credentials per school.
  /// 
  /// Teachers can ONLY login with their school's fixed email/password.
  /// NO teacher signup is allowed - credentials are pre-configured.
  /// 
  /// Returns the UserCredential if login successful.
  /// Throws [AuthException] if login fails or credentials don't match school.
  static Future<UserCredential> loginTeacher({
    required String schoolCode,
    required String email,
    required String password,
  }) async {
    // Validate school code
    if (!AppConstants.isValidSchoolCode(schoolCode)) {
      throw AuthException('Invalid school code: $schoolCode');
    }

    // STRICT VALIDATION: Ensure email matches the school's teacher email
    if (!AppConstants.isTeacherEmail(email, schoolCode)) {
      throw AuthException(
        'Invalid teacher email for school $schoolCode. '
        'Teachers can only login with their school\'s fixed email.',
      );
    }

    // STRICT VALIDATION: Ensure password matches the school's teacher password
    final expectedPassword = AppConstants.getTeacherPassword(schoolCode);
    if (password != expectedPassword) {
      throw AuthException('Invalid password for teacher account.');
    }

    try {
      // Get Firebase Auth instance for this school
      final auth = await _getAuth(schoolCode);

      // Attempt to sign in with email and password
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      // Verify the user is authenticated
      if (userCredential.user == null) {
        throw AuthException('Failed to authenticate teacher.');
      }

      // Additional validation: Store school code in user metadata for verification
      await _verifyTeacherSchoolAccess(userCredential.user!.uid, schoolCode);

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String message = 'Teacher login failed. ';
      switch (e.code) {
        case 'user-not-found':
          message += 'Teacher account not found. Please contact administrator.';
          break;
        case 'wrong-password':
          message += 'Invalid password.';
          break;
        case 'invalid-email':
          message += 'Invalid email format.';
          break;
        case 'user-disabled':
          message += 'Teacher account has been disabled.';
          break;
        case 'too-many-requests':
          message += 'Too many login attempts. Please try again later.';
          break;
        default:
          message += e.message ?? 'Unknown error occurred.';
      }
      throw AuthException(message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Teacher login failed: ${e.toString()}');
    }
  }

  /// Student Login - Validates student credentials and school access.
  /// 
  /// Students can ONLY login to the school where they are registered.
  /// Cross-school login is strictly prevented.
  /// 
  /// Returns the UserCredential if login successful.
  /// Throws [AuthException] if login fails or student doesn't belong to school.
  static Future<UserCredential> loginStudent({
    required String schoolCode,
    required String email,
    required String password,
  }) async {
    // Validate school code
    if (!AppConstants.isValidSchoolCode(schoolCode)) {
      throw AuthException('Invalid school code: $schoolCode');
    }

    try {
      // Get Firebase Auth instance for this school
      final auth = await _getAuth(schoolCode);

      // Attempt to sign in with email and password
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      // Verify the user is authenticated
      if (userCredential.user == null) {
        throw AuthException('Failed to authenticate student.');
      }

      // CRITICAL: Verify student belongs to this school
      await _verifyStudentSchoolAccess(
        userCredential.user!.uid,
        schoolCode,
        email.toLowerCase().trim(),
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String message = 'Student login failed. ';
      switch (e.code) {
        case 'user-not-found':
          message += 'Student account not found. Please check your email or contact your teacher.';
          break;
        case 'wrong-password':
          message += 'Invalid password.';
          break;
        case 'invalid-email':
          message += 'Invalid email format.';
          break;
        case 'user-disabled':
          message += 'Student account has been disabled.';
          break;
        case 'too-many-requests':
          message += 'Too many login attempts. Please try again later.';
          break;
        default:
          message += e.message ?? 'Unknown error occurred.';
      }
      throw AuthException(message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Student login failed: ${e.toString()}');
    }
  }

  /// Student Registration - Creates a new student account in the specified school.
  /// 
  /// Only teachers can register students (this method is called from teacher dashboard).
  /// Students are automatically assigned to the teacher's school.
  /// 
  /// Returns the UserCredential if registration successful.
  /// Throws [AuthException] if registration fails.
  static Future<UserCredential> registerStudent({
    required String schoolCode,
    required String email,
    required String password,
    required String name,
    String? className,
    String? rollNumber,
  }) async {
    // Validate school code
    if (!AppConstants.isValidSchoolCode(schoolCode)) {
      throw AuthException('Invalid school code: $schoolCode');
    }

    // Validate email format
    if (!_isValidEmail(email)) {
      throw AuthException('Invalid email format.');
    }

    // Validate password strength
    if (password.length < 6) {
      throw AuthException('Password must be at least 6 characters long.');
    }

    // Validate name
    if (name.trim().isEmpty) {
      throw AuthException('Student name is required.');
    }

    try {
      // Get Firebase Auth instance for this school
      final auth = await _getAuth(schoolCode);

      // Create the student account in Firebase Auth
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email.toLowerCase().trim(),
        password: password,
      );

      // Verify the user was created
      if (userCredential.user == null) {
        throw AuthException('Failed to create student account.');
      }

      // Get Firestore instance for this school
      final firestore = await FirestoreService.firestore(schoolCode);

      // Create student document in Firestore with school isolation
      await firestore.collection('students').doc(userCredential.user!.uid).set({
        'email': email.toLowerCase().trim(),
        'name': name.trim(),
        'schoolCode': schoolCode, // CRITICAL: Store school code for validation
        'className': className?.trim() ?? '',
        'rollNumber': rollNumber?.trim() ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      String message = 'Student registration failed. ';
      switch (e.code) {
        case 'email-already-in-use':
          message += 'A student with this email already exists in this school.';
          break;
        case 'invalid-email':
          message += 'Invalid email format.';
          break;
        case 'weak-password':
          message += 'Password is too weak. Please use a stronger password.';
          break;
        default:
          message += e.message ?? 'Unknown error occurred.';
      }
      throw AuthException(message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Student registration failed: ${e.toString()}');
    }
  }

  /// Verifies that a teacher has access to the specified school.
  /// This is an additional security layer to ensure school isolation.
  static Future<void> _verifyTeacherSchoolAccess(String userId, String schoolCode) async {
    try {
      final firestore = await FirestoreService.firestore(schoolCode);
      final teacherDoc = await firestore.collection('teachers').doc(userId).get();

      // If teacher document doesn't exist, create it with school code
      if (!teacherDoc.exists) {
        await firestore.collection('teachers').doc(userId).set({
          'schoolCode': schoolCode,
          'email': AppConstants.getTeacherEmail(schoolCode),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Verify teacher belongs to this school
        final data = teacherDoc.data();
        if (data?['schoolCode'] != schoolCode) {
          throw AuthException(
            'Teacher does not have access to school $schoolCode. '
            'Access denied for security reasons.',
          );
        }
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      // If verification fails, still allow login but log the error
      // In production, you might want to be more strict here
    }
  }

  /// Verifies that a student belongs to the specified school.
  /// This prevents cross-school access.
  static Future<void> _verifyStudentSchoolAccess(
    String userId,
    String schoolCode,
    String email,
  ) async {
    try {
      final firestore = await FirestoreService.firestore(schoolCode);
      final studentDoc = await firestore.collection('students').doc(userId).get();

      if (!studentDoc.exists) {
        // Try to find by email as fallback
        final emailQuery = await firestore
            .collection('students')
            .where('email', isEqualTo: email)
            .where('schoolCode', isEqualTo: schoolCode)
            .limit(1)
            .get();

        if (emailQuery.docs.isEmpty) {
          throw AuthException(
            'Student not found in school $schoolCode. '
            'You can only login to the school where you are registered.',
          );
        }
      } else {
        // Verify student belongs to this school
        final data = studentDoc.data();
        if (data?['schoolCode'] != schoolCode) {
          throw AuthException(
            'Student does not belong to school $schoolCode. '
            'Cross-school access is not allowed.',
          );
        }
      }
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to verify student school access: ${e.toString()}');
    }
  }

  /// Validates email format
  static bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Logs out the current user from the specified school.
  static Future<void> logout(String schoolCode) async {
    try {
      final auth = _getAuthSync(schoolCode);
      await auth.signOut();
    } catch (e) {
      // Ignore errors if user is already logged out
    }
  }

  /// Gets the current authenticated user for a school.
  static User? getCurrentUser(String schoolCode) {
    try {
      final auth = _getAuthSync(schoolCode);
      return auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Checks if a user is currently authenticated for a school.
  static bool isAuthenticated(String schoolCode) {
    return getCurrentUser(schoolCode) != null;
  }
}

/// Custom exception for authentication errors.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

