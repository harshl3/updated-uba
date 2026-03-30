import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';
import '../services/auth_service.dart';
import '../school_selection_page.dart';
import 'student_announcement_screen.dart';
import 'transcript_screen.dart';
import 'student_profile_screen.dart';
import '../common/more_menu_page.dart';

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

    // Prevent back navigation - users must logout to go back
    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: SafeArea(
          child: _getCurrentPage(),
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
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
          // ElevatedButton(
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) => TranscriptScreen(
          //           schoolCode: widget.schoolCode,
          //           studentData: _studentData ?? {},
          //         ),
          //       ),
          //     );
          //   },
          //   style: ElevatedButton.styleFrom(
          //     backgroundColor: AppColors.cardWhite,
          //     foregroundColor: AppColors.purpleDark,
          //     elevation: 0,
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          //   ),
          //   child: const Text(
          //     'View Full\nTranscript',
          //     textAlign: TextAlign.center,
          //     style: TextStyle(
          //       fontSize: 12,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StudentProfileScreen(
                        schoolCode: widget.schoolCode,
                        userId: widget.userId,
                        studentData: _studentData ?? {},
                      )
                    ),
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
                        studentClass: _studentData?['className'] as String?,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.business,
                label: 'Results',
                imagePath: 'assets/dashboard/results.png',
                onTap: () {
                  // TODO: Navigate to Results
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Results coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.app_registration,
                label: 'SVPCET Updates',
                imagePath: 'assets/dashboard/studentresult.png',
                onTap: () {
                  // TODO: Navigate to SVPCET Updates
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('updates coming soon!')),
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
            icon: Icon(Icons.announcement),
            label: 'Announcements',
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
        return StudentAnnouncementScreen(
          schoolCode: widget.schoolCode,
          studentClass: _studentData?['className'] as String?,
        );
      case 2:
        return StudentProfileScreen(
          schoolCode: widget.schoolCode,
          userId: widget.userId,
          studentData: _studentData ?? {},
        );
      case 3:
        return MoreMenuPage(
          roleLabel: 'Student',
          onLogout: _handleLogout,
        );
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


  // NOTE: More page is now shared via `MoreMenuPage` (About Us / Contact Us / Logout).
}

