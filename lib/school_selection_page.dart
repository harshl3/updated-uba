import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'role_selection_page.dart';
import 'services/firebase_initialization_service.dart';
import 'constants/app_constants.dart';
import 'theme/app_colors.dart';

class SchoolSelectionPage extends StatefulWidget {
  const SchoolSelectionPage({super.key});

  @override
  State<SchoolSelectionPage> createState() => _SchoolSelectionPageState();
}

class _SchoolSelectionPageState extends State<SchoolSelectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final Map<String, bool> _initializingSchools = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppConstants.animationDuration,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Handles school selection and initializes Firebase for the selected school.
  Future<void> _handleSchoolSelection(String schoolCode) async {
    // Check if already initializing
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
      debugPrint('🚀 Navigating to role selection page...');
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
      
      // Show error message
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

  Widget _buildSchoolButton(String schoolName, String schoolCode) {
    final bool isInitializing = _initializingSchools[schoolCode] == true;
    
    return ScaleTransition(
      scale: _animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            backgroundColor: isInitializing 
                ? AppColors.textSecondary 
                : AppColors.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          onPressed: isInitializing 
              ? null 
              : () => _handleSchoolSelection(schoolCode),
          child: isInitializing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  schoolName,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.school,
                        size: 64,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Select Your School",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              _buildSchoolButton(AppConstants.schoolNameA, AppConstants.schoolCodeA),
              _buildSchoolButton(AppConstants.schoolNameB, AppConstants.schoolCodeB),
              _buildSchoolButton(AppConstants.schoolNameC, AppConstants.schoolCodeC),
            ],
          ),
        ),
      ),
    );
  }
}
