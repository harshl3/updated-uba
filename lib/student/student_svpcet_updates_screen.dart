import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../firestore_service.dart';
import '../theme/app_colors.dart';

class StudentSvpcetUpdatesScreen extends StatelessWidget {
  final String schoolCode;

  const StudentSvpcetUpdatesScreen({super.key, required this.schoolCode});

  Stream<QuerySnapshot> _getUpdatesStream() {
    return Stream.fromFuture(
      FirestoreService.firestore(schoolCode),
    ).asyncExpand((firestore) {
      return firestore
          .collection('svpcet_updates')
          .where('schoolCode', isEqualTo: schoolCode)
          .snapshots();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVPCET Updates'),
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: StreamBuilder<QuerySnapshot>(
          stream: _getUpdatesStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No SVPCET updates yet.',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            final updates = snapshot.data!.docs;
            updates.sort((a, b) {
              final timestampA =
                  (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final timestampB =
                  (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (timestampA == null || timestampB == null) return 0;
              return timestampB.compareTo(timestampA);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: updates.length,
              itemBuilder: (context, index) {
                final update = updates[index].data() as Map<String, dynamic>;
                final title = update['title'] ?? 'No Title';
                final message = update['message'] ?? 'No message';
                final date = update['date'] ?? '';
                final time = update['time'] ?? '';

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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SVPCET UPDATE',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (date.isNotEmpty || time.isNotEmpty)
                          Row(
                            children: [
                              if (date.isNotEmpty) ...[
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                              if (date.isNotEmpty && time.isNotEmpty)
                                const SizedBox(width: 16),
                              if (time.isNotEmpty) ...[
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  time,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
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
}
