import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';
import 'student_details_screen.dart';

/// Students List Screen - Shows all registered students for the school
/// 
/// Teachers can view and access student details.
/// All data is school-scoped and isolated.
class StudentsListScreen extends StatefulWidget {
  final String schoolCode;

  const StudentsListScreen({
    super.key,
    required this.schoolCode,
  });

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Students'),
                  content: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter student name or email',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: FutureBuilder<Stream<QuerySnapshot>>(
          future: _getStudentsStream(),
          builder: (context, streamSnapshot) {
            if (!streamSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: streamSnapshot.data,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
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
                          'Error loading students: ${snapshot.error}',
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
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No students registered yet.',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final students = snapshot.data!.docs;
                
                // Sort and filter students
                final sortedStudents = List.from(students);
                sortedStudents.sort((a, b) {
                  final nameA = (a.data() as Map<String, dynamic>)['name'] as String? ?? '';
                  final nameB = (b.data() as Map<String, dynamic>)['name'] as String? ?? '';
                  return nameA.toLowerCase().compareTo(nameB.toLowerCase());
                });

                // Filter by search query
                final filteredStudents = _searchQuery.isEmpty
                    ? sortedStudents
                    : sortedStudents.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] as String? ?? '').toLowerCase();
                        final email = (data['email'] as String? ?? '').toLowerCase();
                        return name.contains(_searchQuery) || email.contains(_searchQuery);
                      }).toList();

                if (filteredStudents.isEmpty) {
                  return const Center(
                    child: Text(
                      'No students found matching your search.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredStudents.length,
                  itemBuilder: (context, index) {
                    final student = filteredStudents[index].data() as Map<String, dynamic>;
                    final studentId = filteredStudents[index].id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryBlue,
                          child: Text(
                            (student['name'] as String? ?? 'N')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          student['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Email: ${student['email'] ?? 'N/A'}'),
                            if (student['className'] != null &&
                                (student['className'] as String).isNotEmpty)
                              Text('Class: ${student['className']}'),
                            if (student['currentPercentage'] != null &&
                                (student['currentPercentage'] as String).isNotEmpty)
                              Text('Percentage: ${student['currentPercentage']}%'),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentDetailsScreen(
                                schoolCode: widget.schoolCode,
                                studentId: studentId,
                                studentData: student,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Gets the stream of students for the current school
  Future<Stream<QuerySnapshot>> _getStudentsStream() async {
    final firestore = await FirestoreService.firestore(widget.schoolCode);
    return firestore
        .collection('students')
        .where('schoolCode', isEqualTo: widget.schoolCode)
        .snapshots();
  }
}


