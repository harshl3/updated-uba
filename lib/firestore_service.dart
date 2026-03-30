import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'school_selector.dart';

/// Service for accessing Firestore with school-specific Firebase instances.
class FirestoreService {
  /// Gets Firestore instance for a specific school.
  /// Automatically initializes Firebase if needed.
  static Future<FirebaseFirestore> firestore(String schoolCode) async {
    final FirebaseApp app = await SchoolSelector.getApp(schoolCode);
    return FirebaseFirestore.instanceFor(app: app);
  }

  /// Synchronously gets Firestore instance (throws if Firebase not initialized).
  /// Use this only when you're certain Firebase is already initialized.
  static FirebaseFirestore firestoreSync(String schoolCode) {
    final FirebaseApp app = SchoolSelector.getAppSync(schoolCode);
    return FirebaseFirestore.instanceFor(app: app);
  }
}
