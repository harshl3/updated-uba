import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_registration_page.dart';
import 'constants/app_constants.dart';
import 'firestore_service.dart';
import 'services/auth_service.dart';
import 'school_selection_page.dart';

/// Dashboard page that displays different views for teachers and students.
/// 
/// Teachers: Can register students and view list of all students in their school
/// Students: Can view their own profile information
class DashboardPage extends StatefulWidget {
  final String schoolCode;
  final String role;
  final String email;
  final String userId;

  const DashboardPage({
    super.key,
    required this.schoolCode,
    required this.role,
    required this.email,
    required this.userId,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _studentData;

  @override
  void initState() {
    super.initState();
    if (widget.role == AppConstants.roleStudent) {
      _loadStudentData();
    } else {
      _isLoading = false;
    }
  }

  /// Loads student data from Firestore (for student view)
  Future<void> _loadStudentData() async {
    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);
      final studentDoc =
          await firestore.collection('students').doc(widget.userId).get();

      if (mounted) {
        setState(() {
          _studentData = studentDoc.data();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load student data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handles logout for both teachers and students
  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await AuthService.logout(widget.schoolCode);
        if (!mounted) return;

        // Navigate back to school selection
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const SchoolSelectionPage(),
          ),
          (route) => false,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isTeacher = widget.role == AppConstants.roleTeacher;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role.toUpperCase()} Dashboard'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : isTeacher
                ? _buildTeacherDashboard()
                : _buildStudentDashboard(),
      ),
    );
  }

  /// Builds the teacher dashboard with student registration and list
  Widget _buildTeacherDashboard() {
    return Column(
      children: [
        // Welcome card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.school,
                size: 48,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome, Teacher!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'School ${widget.schoolCode}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // Register student button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentRegistrationPage(
                      schoolCode: widget.schoolCode,
                    ),
                  ),
                ).then((_) {
                  // Refresh student list if needed
                  setState(() {});
                });
              },
              icon: const Icon(Icons.person_add),
              label: const Text(
                'Register New Student',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Students list header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                'Registered Students',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Students list
        Expanded(
          child: _buildStudentsList(),
        ),
      ],
    );
  }

  /// Builds the list of students (for teachers)
  Widget _buildStudentsList() {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: _getStudentsStream(),
      builder: (context, streamSnapshot) {
        if (!streamSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: streamSnapshot.data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
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
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading students: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
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
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No students registered yet.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Click "Register New Student" to add students.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              );
            }

            final students = snapshot.data!.docs;
            
            // Sort students by name in memory (since we removed orderBy to avoid index requirement)
            final sortedStudents = List.from(students);
            sortedStudents.sort((a, b) {
              final nameA = (a.data() as Map<String, dynamic>)['name'] as String? ?? '';
              final nameB = (b.data() as Map<String, dynamic>)['name'] as String? ?? '';
              return nameA.toLowerCase().compareTo(nameB.toLowerCase());
            });

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: sortedStudents.length,
              itemBuilder: (context, index) {
                final student = sortedStudents[index].data() as Map<String, dynamic>;
                final studentId = sortedStudents[index].id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Text(
                        (student['name'] as String? ?? 'N')
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
                        Text('Email: ${student['email'] ?? 'N/A'}'),
                        if (student['className'] != null &&
                            (student['className'] as String).isNotEmpty)
                          Text('Class: ${student['className']}'),
                        if (student['rollNumber'] != null &&
                            (student['rollNumber'] as String).isNotEmpty)
                          Text('Roll: ${student['rollNumber']}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Show student details dialog
                      _showStudentDetails(student, studentId);
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Gets the stream of students for the current school
  /// Returns a Future that resolves to a Stream for proper async handling
  /// Note: We filter by schoolCode only (no orderBy) to avoid requiring a composite index.
  /// Sorting can be done in memory if needed.
  Future<Stream<QuerySnapshot>> _getStudentsStream() async {
    final firestore = await FirestoreService.firestore(widget.schoolCode);
    // Only filter by schoolCode - no orderBy to avoid index requirement
    // The list will be sorted in memory in the UI if needed
    return firestore
        .collection('students')
        .where('schoolCode', isEqualTo: widget.schoolCode)
        .snapshots();
  }

  /// Shows student details in a dialog
  void _showStudentDetails(Map<String, dynamic> student, String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student['name'] ?? 'Student Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Email', student['email'] ?? 'N/A'),
              _buildDetailRow('Name', student['name'] ?? 'N/A'),
              _buildDetailRow('Class', student['className'] ?? 'Not specified'),
              _buildDetailRow('Roll Number', student['rollNumber'] ?? 'Not specified'),
              _buildDetailRow('School', 'School ${widget.schoolCode}'),
              if (student['createdAt'] != null)
                _buildDetailRow(
                  'Registered',
                  _formatTimestamp(student['createdAt']),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Unknown';
  }

  /// Builds the student dashboard with profile information
  Widget _buildStudentDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.person,
                  size: 64,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 16),
                Text(
                  _studentData?['name'] ?? 'Student',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'School ${widget.schoolCode}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Student details card
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
                  const Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.email, 'Email', widget.email),
                  if (_studentData?['name'] != null)
                    _buildInfoRow(
                      Icons.person,
                      'Name',
                      _studentData!['name'],
                    ),
                  if (_studentData?['className'] != null &&
                      (_studentData!['className'] as String).isNotEmpty)
                    _buildInfoRow(
                      Icons.class_,
                      'Class',
                      _studentData!['className'],
                    ),
                  if (_studentData?['rollNumber'] != null &&
                      (_studentData!['rollNumber'] as String).isNotEmpty)
                    _buildInfoRow(
                      Icons.numbers,
                      'Roll Number',
                      _studentData!['rollNumber'],
                    ),
                  _buildInfoRow(
                    Icons.school,
                    'School',
                    'School ${widget.schoolCode}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
