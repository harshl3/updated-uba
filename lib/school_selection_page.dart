import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'role_selection_page.dart';
import 'services/firebase_initialization_service.dart';
import 'constants/app_constants.dart';
import 'theme/app_colors.dart';

/// School Selection Screen
///
/// Welcomes users with an education-themed interface and allows them to
/// choose their institution (School A, B, or C). Initializes the respective
/// Firebase project and routes to role selection.
class SchoolSelectionPage extends StatefulWidget {
  const SchoolSelectionPage({super.key});

  @override
  State<SchoolSelectionPage> createState() => _SchoolSelectionPageState();
}

class _SchoolSelectionPageState extends State<SchoolSelectionPage> {
  final Map<String, bool> _initializingSchools = {};

  /// Handles school selection and initializes Firebase for the selected school.
  Future<void> _handleSchoolSelection(String schoolCode) async {
    if (_initializingSchools[schoolCode] == true) {
      return;
    }

    if (kDebugMode) {
      debugPrint('📚 User selected School $schoolCode');
    }

    setState(() {
      _initializingSchools[schoolCode] = true;
    });

    try {
      // Initialize Firebase for the selected school
      await FirebaseInitializationService.initializeForSchool(schoolCode);

      if (kDebugMode) {
        debugPrint('✅ Firebase initialization complete for School $schoolCode');
      }

      if (!mounted) return;

      // Navigate to role selection page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoleSelectionPage(schoolCode: schoolCode),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error initializing School $schoolCode: $e');
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initialize school: ${e.toString()}'),
          backgroundColor: AppColors.red,
          duration: AppConstants.snackbarDurationLong,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _initializingSchools[schoolCode] = false;
        });
      }
    }
  }

  Widget _buildSchoolCard({
    required String schoolName,
    required String schoolCode,
    required String subtitle,
    required IconData icon,
  }) {
    final bool isInitializing = _initializingSchools[schoolCode] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isInitializing ? null : () => _handleSchoolSelection(schoolCode),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isInitializing ? AppColors.primaryBlue : AppColors.borderLight,
                width: isInitializing ? 1.5 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 26,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Name & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schoolName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Trailing Action / Loader
                if (isInitializing)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                    ),
                  )
                else
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueAlt,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.primaryBlue,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clean Education Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderLight, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      size: 40,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  "Select Your School",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                const Text(
                  "Choose your school to continue to the portal.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // School Cards List
                _buildSchoolCard(
                  schoolName: AppConstants.schoolNameA,
                  schoolCode: AppConstants.schoolCodeA,
                  subtitle: "Portal for School A students & teachers",
                  icon: Icons.account_balance_rounded,
                ),
                _buildSchoolCard(
                  schoolName: AppConstants.schoolNameB,
                  schoolCode: AppConstants.schoolCodeB,
                  subtitle: "Portal for School B students & teachers",
                  icon: Icons.apartment_rounded,
                ),
                _buildSchoolCard(
                  schoolName: AppConstants.schoolNameC,
                  schoolCode: AppConstants.schoolCodeC,
                  subtitle: "Portal for School C students & teachers",
                  icon: Icons.domain_rounded,
                ),

                const SizedBox(height: 28),

                // Footer branding badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: AppColors.textSecondary),
                      SizedBox(width: 6),
                      Text(
                        "Unnat Bharat Abhiyan (UBA)",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
