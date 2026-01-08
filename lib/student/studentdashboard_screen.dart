import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';
import '../services/auth_service.dart';
import '../school_selection_page.dart';

/// Student Dashboard Screen
/// 
/// Main dashboard for students showing:
/// - CGPA/Performance card
/// - Announcements
/// - Quick access to various features (Student Details, Attendance, Study Material, etc.)
/// - Bottom navigation bar
/// 
/// All data is school-scoped and isolated per school.
class StudentDashboardScreen extends StatefulWidget {
  final String schoolCode;
  final String email;
  final String userId;

  const StudentDashboardScreen({
    super.key,
    required this.schoolCode,
    required this.email,
    required this.userId,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0; // For bottom navigation
  Map<String, dynamic>? _studentData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  /// Loads student data from Firestore
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load student data: ${e.toString()}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      }
    }
  }

  /// Handles logout
  Future<void> _handleLogout() async {
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
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: _getCurrentPage(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Builds the top header with user name and notification icon
  Widget _buildHeader() {
    final studentName = _studentData?['name'] ?? 'Student';
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Profile Icon
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.primaryBlue,
            child: Text(
              studentName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // User Name
          Expanded(
            child: Text(
              studentName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          // Notification Icon
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.textPrimary,
            onPressed: () {
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          // Logout Icon
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds the Percentage card with purple gradient
  Widget _buildCGPACard() {
    // Fetch actual percentage from Firestore
    final percentage = _studentData?['currentPercentage'] ?? '';
    final displayPercentage = percentage.isNotEmpty ? percentage : 'N/A';
    final studentName = _studentData?['name'] ?? 'Student';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.purpleGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDark.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $studentName',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your current Percentage',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayPercentage == 'N/A' ? displayPercentage : '$displayPercentage%',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // View Full Transcript Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranscriptScreen(
                    schoolCode: widget.schoolCode,
                    studentData: _studentData ?? {},
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardWhite,
              foregroundColor: AppColors.purpleDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'View Full\nTranscript',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Builds the student dashboard grid with feature cards
  Widget _buildDashboardGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildDashboardCard(
                icon: Icons.school,
                label: 'Student Details',
                imagePath: 'assets/dashboard/studentdetails.png',
                onTap: () {
                  // TODO: Navigate to student details
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student Details coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.calendar_today,
                label: 'Attendance',
                imagePath: 'assets/dashboard/attendance.jpg',
                onTap: () {
                  // TODO: Navigate to attendance
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.book,
                label: 'Study Material',
                imagePath: 'assets/dashboard/studymaterial.png',
                onTap: () {
                  // TODO: Navigate to study material
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study Material coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.campaign,
                label: 'Announcement',
                imagePath: 'assets/dashboard/announcement.png',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentAnnouncementScreen(
                        schoolCode: widget.schoolCode,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.business,
                label: 'YOJINAA',
                imagePath: 'assets/dashboard/yojnaa.png',
                onTap: () {
                  // TODO: Navigate to YOJINAA
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('YOJINAA coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.app_registration,
                label: 'Registration',
                imagePath: 'assets/dashboard/register.png',
                onTap: () {
                  // TODO: Navigate to registration
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Registration coming soon!')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds individual dashboard card
  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Try to load image, fallback to icon
            Image.asset(
              imagePath,
              width: 48,
              height: 48,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  icon,
                  size: 48,
                  color: AppColors.primaryBlue,
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds bottom navigation bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  /// Gets the current page based on bottom navigation
  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return _buildAttendancePage();
      case 2:
        return StudentProfileScreen(
          schoolCode: widget.schoolCode,
          userId: widget.userId,
          studentData: _studentData ?? {},
        );
      case 3:
        return _buildMorePage();
      default:
        return _buildHomeContent();
    }
  }

  /// Builds home content
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildCGPACard(),
          _buildDashboardGrid(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds attendance page
  Widget _buildAttendancePage() {
    return const Center(
      child: Text('Attendance feature coming soon!'),
    );
  }

  /// Builds more page
  Widget _buildMorePage() {
    return const Center(
      child: Text('More features coming soon!'),
    );
  }
}

/// Student Announcement Screen - Shows all announcements for the student's school
class StudentAnnouncementScreen extends StatelessWidget {
  final String schoolCode;

  const StudentAnnouncementScreen({
    super.key,
    required this.schoolCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
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
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No announcements yet.'),
              );
            }

            final announcements = snapshot.data!.docs;
            announcements.sort((a, b) {
              final timestampA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              final timestampB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
              if (timestampA == null || timestampB == null) return 0;
              return timestampB.compareTo(timestampA); // Newest first
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (context, index) {
                final announcement = announcements[index].data() as Map<String, dynamic>;
                final title = announcement['title'] ?? 'No Title';
                final message = announcement['message'] ?? 'No message';
                final date = announcement['date'] ?? '';
                final time = announcement['time'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
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
  /// Sorting is done in memory
  Stream<QuerySnapshot> _getAnnouncementsStream() {
    return Stream.fromFuture(
      FirestoreService.firestore(schoolCode),
    ).asyncExpand((firestore) {
      return firestore
          .collection('announcements')
          .where('schoolCode', isEqualTo: schoolCode)
          .snapshots();
    });
  }
}

/// Transcript Screen - Shows student's academic performance
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

/// Student Profile Screen - Shows student's personal details
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Profile Header
              Card(
                elevation: 4,
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
                children: [
                  _buildInfoRow("Father's Name", studentData['fathersName'] ?? 'Not specified'),
                  _buildInfoRow("Parent's Mobile", studentData['parentsMobileNumber'] ?? 'Not specified'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

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

