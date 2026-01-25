import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';
import 'student_details_screen.dart';

/// Students List Screen - Shows registered students for the school
class StudentsListScreen extends StatefulWidget {
  final String schoolCode;
  final String? selectedClass;

  const StudentsListScreen({
    super.key,
    required this.schoolCode,
    this.selectedClass,
  });

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: FutureBuilder<Stream<QuerySnapshot>>(
        future: _getStudentsStream(),
        builder: (context, streamSnapshot) {
          if (!streamSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Students heading (NO blue background)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Students',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              // Search box section (faint background)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              // Students list
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: streamSnapshot.data,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading students',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No students registered yet.',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    final students = snapshot.data!.docs;

                    final sortedStudents = List.from(students)
                      ..sort((a, b) {
                        final nameA =
                            (a.data() as Map<String, dynamic>)['name'] ?? '';
                        final nameB =
                            (b.data() as Map<String, dynamic>)['name'] ?? '';
                        return nameA
                            .toString()
                            .toLowerCase()
                            .compareTo(nameB.toString().toLowerCase());
                      });

                    final filteredStudents = _searchQuery.isEmpty
                        ? sortedStudents
                        : sortedStudents.where((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final name =
                      (data['name'] ?? '').toString().toLowerCase();
                      final email =
                      (data['email'] ?? '').toString().toLowerCase();
                      return name.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                    }).toList();

                    if (filteredStudents.isEmpty) {
                      return const Center(
                        child: Text(
                          'No students found.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredStudents.length,
                      itemBuilder: (context, index) {
                        final student =
                        filteredStudents[index].data()
                        as Map<String, dynamic>;
                        final studentId = filteredStudents[index].id;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryBlue,
                              child: Text(
                                (student['name'] ?? 'N')
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
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
                                Text(
                                  student['email'] ?? 'N/A',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                if (student['className'] != null)
                                  Text(
                                    'Class: ${student['className']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: AppColors.textSecondary,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentDetailsScreen(
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Firestore stream
  Future<Stream<QuerySnapshot>> _getStudentsStream() async {
    final firestore = await FirestoreService.firestore(widget.schoolCode);

    if (widget.selectedClass != null &&
        widget.selectedClass!.isNotEmpty) {
      return firestore
          .collection('students')
          .where('schoolCode', isEqualTo: widget.schoolCode)
          .where('className', isEqualTo: widget.selectedClass)
          .snapshots();
    }

    return firestore
        .collection('students')
        .where('schoolCode', isEqualTo: widget.schoolCode)
        .snapshots();
  }
}
