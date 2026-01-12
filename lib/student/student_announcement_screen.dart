import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';

/// Student Announcement Screen - Shows announcements for the student's school and class
/// 
/// Displays announcements with date and time.
/// Filters announcements based on student's class:
/// - Shows announcements with targetClass = 'all' (for all students)
/// - Shows announcements with targetClass matching student's class
/// All announcements are school-scoped and isolated.
class StudentAnnouncementScreen extends StatefulWidget {
  final String schoolCode;
  final String? studentClass; // Student's class (1-12)

  const StudentAnnouncementScreen({
    super.key,
    required this.schoolCode,
    this.studentClass,
  });

  @override
  State<StudentAnnouncementScreen> createState() => _StudentAnnouncementScreenState();
}

class _StudentAnnouncementScreenState extends State<StudentAnnouncementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        // Allow back navigation within app (to dashboard)
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: StreamBuilder<QuerySnapshot>(
          stream: _getAnnouncementsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.textPrimary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No announcements yet.',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            // Filter announcements based on student's class
            final allAnnouncements = snapshot.data!.docs;
            final filteredAnnouncements = allAnnouncements.where((doc) {
              final announcement = doc.data() as Map<String, dynamic>;
              final targetClass = announcement['targetClass'] as String? ?? 'all';
              
              // Show if: targetClass is 'all' OR matches student's class
              if (targetClass == 'all') {
                return true;
              }
              
              // If student has a class, show only matching announcements
              if (widget.studentClass != null && widget.studentClass!.isNotEmpty) {
                return targetClass == widget.studentClass;
              }
              
              // If student has no class, show only 'all' announcements
              return false;
            }).toList();
            
            // Check if filtered announcements are empty
            if (filteredAnnouncements.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      size: 64,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.studentClass != null && widget.studentClass!.isNotEmpty
                          ? 'No announcements for Class ${widget.studentClass} yet.'
                          : 'No announcements available.',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            // Sort announcements by timestamp (newest first)
            filteredAnnouncements.sort((a, b) {
              final timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (timestampA == null || timestampB == null) return 0;
              return timestampB.compareTo(timestampA); // Newest first
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredAnnouncements.length,
              itemBuilder: (context, index) {
                final announcement = filteredAnnouncements[index].data() as Map<String, dynamic>;
                final title = announcement['title'] ?? 'No Title';
                final message = announcement['message'] ?? 'No message';
                final date = announcement['date'] ?? '';
                final time = announcement['time'] ?? '';
                final targetClass = announcement['targetClass'] as String? ?? 'all';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'ANNOUNCEMENT',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (targetClass != 'all')
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Class $targetClass',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (date.isNotEmpty || time.isNotEmpty)
                          Row(
                            children: [
                              if (date.isNotEmpty) ...[
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                              if (date.isNotEmpty && time.isNotEmpty) const SizedBox(width: 16),
                              if (time.isNotEmpty) ...[
                                const Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 12),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Gets announcements stream for the school
  /// Note: We don't use orderBy here to avoid index requirement
  /// Sorting and filtering by class is done in memory
  Stream<QuerySnapshot> _getAnnouncementsStream() {
    return Stream.fromFuture(
      FirestoreService.firestore(widget.schoolCode),
    ).asyncExpand((firestore) {
      return firestore
          .collection('announcements')
          .where('schoolCode', isEqualTo: widget.schoolCode)
          .snapshots();
    });
  }
}
