import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';
import '../services/auth_service.dart';
import '../school_selection_page.dart';
import '../student_registration_page.dart';
import 'students_list_screen.dart';
import 'announcement_screen.dart';

/// Teacher Dashboard Screen
/// 
/// Main dashboard for teachers showing:
/// - Welcome card with school info
/// - Quick stats (total students, etc.)
/// - Student registration button
/// - List of registered students
/// - Quick access to various features
/// 
/// All data is school-scoped and isolated per school.
class TeacherDashboardScreen extends StatefulWidget {
  final String schoolCode;
  final String email;
  final String userId;

  const TeacherDashboardScreen({
    super.key,
    required this.schoolCode,
    required this.email,
    required this.userId,
  });

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  int _currentIndex = 0; // For bottom navigation
  bool _isLoading = true;
  int _totalStudents = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  /// Loads initial data for teacher dashboard
  Future<void> _loadInitialData() async {
    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);
      final studentsSnapshot = await firestore
          .collection('students')
          .where('schoolCode', isEqualTo: widget.schoolCode)
          .get();

      if (mounted) {
        setState(() {
          _totalStudents = studentsSnapshot.docs.length;
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
            content: Text('Failed to load data: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
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
      appBar: AppBar(
        title: const Text('Teacher Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: _getCurrentPage(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  /// Builds welcome card with teacher info
  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.school,
                size: 32,
                color: AppColors.textWhite,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Teacher!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'School ${widget.schoolCode}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.email,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds stats card showing total students
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.people,
            label: 'Total Students',
            value: _totalStudents.toString(),
            color: AppColors.primaryBlue,
          ),
          _buildStatItem(
            icon: Icons.school,
            label: 'School',
            value: widget.schoolCode,
            color: AppColors.green,
          ),
        ],
      ),
    );
  }

  /// Builds individual stat item
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Builds register student button
  Widget _buildRegisterButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      height: 56,
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
            // Refresh data after registration
            _loadInitialData();
          });
        },
        icon: const Icon(Icons.person_add, size: 24),
        label: const Text(
          'Register New Student',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: AppColors.textWhite,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Gets the current page based on bottom navigation index
  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return StudentsListScreen(schoolCode: widget.schoolCode);
      case 2:
        return _buildProfilePage();
      case 3:
        return _buildMorePage();
      default:
        return _buildHomePage();
    }
  }

  /// Builds the home page content
  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          _buildWelcomeCard(),
          
          // Quick Stats Card
          _buildStatsCard(),
          
          // Register Student Button
          _buildRegisterButton(),
          
          // Teacher Dashboard Grid
          _buildDashboardGrid(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Builds teacher dashboard grid with feature cards
  Widget _buildDashboardGrid() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Teacher Dashboard',
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
                icon: Icons.people,
                label: 'Student Details',
                imagePath: 'assets/dashboard/studentdetails.png',
                onTap: () {
                  // TODO: Navigate to student details management
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
                  // TODO: Navigate to attendance management
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Attendance management coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.book,
                label: 'Study Material',
                imagePath: 'assets/dashboard/studymaterial.png',
                onTap: () {
                  // TODO: Navigate to study material upload
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
                      builder: (context) => AnnouncementScreen(
                        schoolCode: widget.schoolCode,
                      ),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.assessment,
                label: 'Results',
                imagePath: 'assets/dashboard/results.png',
                onTap: () {
                  // TODO: Navigate to results management
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Results management coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.history,
                label: 'History',
                imagePath: 'assets/dashboard/history.png',
                onTap: () {
                  // TODO: Navigate to history
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('History coming soon!')),
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
            icon: Icon(Icons.people),
            label: 'Students',
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

  /// Builds profile page
  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, size: 48),
              title: const Text('Teacher Profile'),
              subtitle: Text(widget.email),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds more page
  Widget _buildMorePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

