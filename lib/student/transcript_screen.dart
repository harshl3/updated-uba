import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Transcript Screen - Shows student's academic performance
/// 
/// Displays previous and current percentage in a clear, organized format.
class TranscriptScreen extends StatelessWidget {
  final String schoolCode;
  final Map<String, dynamic> studentData;

  const TranscriptScreen({
    super.key,
    required this.schoolCode,
    required this.studentData,
  });

  @override
  Widget build(BuildContext context) {
    final previousPercentage = studentData['previousPercentage'] ?? 'Not Available';
    final currentPercentage = studentData['currentPercentage'] ?? 'Not Available';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Transcript'),
        // Allow back navigation within app (to dashboard)
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                        radius: 40,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          (studentData['name'] ?? 'S').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 32,
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
                        'School $schoolCode',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Previous Percentage Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.history, color: AppColors.primaryBlue),
                          SizedBox(width: 8),
                          Text(
                            'Previous Percentage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        previousPercentage == 'Not Available' 
                            ? previousPercentage 
                            : '$previousPercentage%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: previousPercentage == 'Not Available' 
                              ? AppColors.textSecondary 
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Current Percentage Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_up, color: AppColors.green),
                          SizedBox(width: 8),
                          Text(
                            'Current Percentage',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentPercentage == 'Not Available' 
                            ? currentPercentage 
                            : '$currentPercentage%',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: currentPercentage == 'Not Available' 
                              ? AppColors.textSecondary 
                              : AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
