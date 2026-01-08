import 'package:flutter/material.dart';
import 'login_page.dart';
import 'constants/app_constants.dart';
import 'theme/app_colors.dart';

/// Role selection page - allows users to choose between Teacher or Student login.
/// 
/// After selecting a role, users are taken to the appropriate login page.
class RoleSelectionPage extends StatelessWidget {
  final String schoolCode;
  const RoleSelectionPage({super.key, required this.schoolCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Role"),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        color: AppColors.backgroundLight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // School info card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.school,
                        size: 48,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'School $schoolCode',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Select Your Role",
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Student button
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          schoolCode: schoolCode,
                          role: AppConstants.roleStudent,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person, size: 28),
                  label: const Text(
                    "Student",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Teacher button
              SizedBox(
                width: double.infinity,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(
                          schoolCode: schoolCode,
                          role: AppConstants.roleTeacher,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.school, size: 28),
                  label: const Text(
                    "Teacher",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.textWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Info text
              const Text(
                'Choose your role to continue',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
