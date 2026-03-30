import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Student Profile Screen - Shows student's personal details
/// 
/// Displays comprehensive student information organized in sections:
/// - Personal Information
/// - Academic Information
/// - Contact Information
class StudentProfileScreen extends StatelessWidget {
  final String schoolCode;
  final String userId;
  final Map<String, dynamic> studentData;

  const StudentProfileScreen({
    super.key,
    required this.schoolCode,
    required this.userId,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    // This widget is used as body content (no Scaffold wrapper)
    return Container(
        color: AppColors.backgroundLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          (studentData['name'] ?? 'S').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        studentData['name'] ?? 'Student',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        studentData['email'] ?? 'No Email',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Personal Information
              _buildSectionCard(
                title: 'Personal Information',
                icon: Icons.person,
                children: [
                  _buildInfoRow('Name', studentData['name'] ?? 'Not specified'),
                  _buildInfoRow('Email', studentData['email'] ?? 'Not specified'),
                  _buildInfoRow('Gender', studentData['gender'] ?? 'Not specified'),
                  _buildInfoRow('Date of Birth', studentData['dob'] ?? 'Not specified'),
                  _buildInfoRow('Mobile Number', studentData['mobileNumber'] ?? 'Not specified'),
                  _buildInfoRow('Address', studentData['address'] ?? 'Not specified'),
                ],
              ),
              
              // Academic Information
              _buildSectionCard(
                title: 'Academic Information',
                icon: Icons.school,
                children: [
                  _buildInfoRow('Class', studentData['className'] ?? 'Not specified'),
                  _buildInfoRow('Roll Number', studentData['rollNumber'] ?? 'Not specified'),
                  _buildInfoRow('Date of Admission', studentData['dateOfAdmission'] ?? 'Not specified'),
                  _buildInfoRow('Previous Percentage', 
                      studentData['previousPercentage'] != null && studentData['previousPercentage'].toString().isNotEmpty
                          ? '${studentData['previousPercentage']}%'
                          : 'Not specified'),
                  _buildInfoRow('Current Percentage', 
                      studentData['currentPercentage'] != null && studentData['currentPercentage'].toString().isNotEmpty
                          ? '${studentData['currentPercentage']}%'
                          : 'Not specified'),
                ],
              ),
              
              // Contact Information
              _buildSectionCard(
                title: 'Contact Information',
                icon: Icons.contact_phone,
                children: [
                  _buildInfoRow("Father's Name", studentData['fathersName'] ?? 'Not specified'),
                  _buildInfoRow("Parent's Mobile", studentData['parentsMobileNumber'] ?? 'Not specified'),
                ],
              ),
            ],
          ),
        ),
    );
  }

  /// Builds a section card with title and children widgets
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Builds an information row with label and value
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
