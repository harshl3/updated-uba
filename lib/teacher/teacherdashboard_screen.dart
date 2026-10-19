import 'package:flutter/material.dart';
import 'package:vidya_sathi/teacher/students_list_screen.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';
import '../services/auth_service.dart';
import '../school_selection_page.dart';
import '../student_registration_page.dart';
import 'announcement_screen.dart';
import 'class_selection_screen.dart';
import '../common/more_menu_page.dart';
import 'attendance_screen.dart';
import 'attendance_report_screen.dart';
import 'svpcet_updates_screen.dart';

/// Teacher Dashboard Screen
///
/// Main dashboard for teachers showing:
/// - Polished app bar
/// - Welcome card with gradient accent
/// - Compact quick statistics
/// - Prominent Register Student action
/// - Consistent 2-column quick actions grid
/// - Modern 4-tab bottom navigation
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
  int _currentIndex = 0;
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
            content: Text('Failed to load dashboard data: ${e.toString()}'),
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
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(90, 40),
            ),
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
          MaterialPageRoute(builder: (context) => const SchoolSelectionPage()),
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
      return const Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          title: const Text('Teacher Dashboard'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded),
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications are up to date.')),
                );
              },
            ),
          ],
        ),
        body: SafeArea(child: _getCurrentPage()),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  /// Builds welcome card with teacher info
  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.welcomeGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Teacher Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'School ${widget.schoolCode}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // School Code Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.schoolCode,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Compact statistics summary card
  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Icons.groups_rounded,
              label: 'Total Students',
              value: _totalStudents.toString(),
              color: AppColors.primaryBlue,
              bgColor: AppColors.lightBlue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.borderLight,
          ),
          Expanded(
            child: _buildStatItem(
              icon: Icons.apartment_rounded,
              label: 'Assigned School',
              value: 'School ${widget.schoolCode}',
              color: AppColors.green,
              bgColor: AppColors.greenLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  /// Register Student Quick Action Banner
  Widget _buildRegisterButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentRegistrationPage(schoolCode: widget.schoolCode),
              ),
            ).then((_) => _loadInitialData());
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.greenLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded, size: 22, color: AppColors.green),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Register New Student',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Enroll a student to School roster',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Current page according to bottom navigation bar index
  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return StudentsListScreen(
          schoolCode: widget.schoolCode,
          selectedClass: null,
        );
      case 2:
        return AttendanceScreen(schoolCode: widget.schoolCode);
      case 3:
        return MoreMenuPage(roleLabel: 'Teacher', onLogout: _handleLogout);
      default:
        return _buildHomePage();
    }
  }

  /// Builds home tab content with scroll padding to avoid bottom bar overlap
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          _buildStatsCard(),
          _buildRegisterButton(),
          _buildDashboardGrid(),
        ],
      ),
    );
  }

  /// 2-Column Quick Actions Grid
  Widget _buildDashboardGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Quick Management',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              _buildDashboardCard(
                icon: Icons.groups_rounded,
                label: 'Student Details',
                color: const Color(0xFF3478E5),
                bgColor: const Color(0xFFEAF6FC),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ClassSelectionScreen(schoolCode: widget.schoolCode),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.how_to_reg_rounded,
                label: 'Daily Attendance',
                color: const Color(0xFF20B96B),
                bgColor: const Color(0xFFE8F8F0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceScreen(schoolCode: widget.schoolCode),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.description_rounded,
                label: 'Attendance Report',
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceReportScreen(schoolCode: widget.schoolCode),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.campaign_rounded,
                label: 'Announcements',
                color: const Color(0xFFEA580C),
                bgColor: const Color(0xFFFFEDD5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnouncementScreen(schoolCode: widget.schoolCode),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.menu_book_rounded,
                label: 'Study Material',
                color: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF3E8FF),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Study Material repository coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.analytics_rounded,
                label: 'Results',
                color: const Color(0xFF0D9488),
                bgColor: const Color(0xFFCCFBF1),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Results management module coming soon!')),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.notifications_active_rounded,
                label: 'School Updates',
                color: const Color(0xFF4F46E5),
                bgColor: const Color(0xFFEEF2FF),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SvpcetUpdatesScreen(schoolCode: widget.schoolCode),
                    ),
                  );
                },
              ),
              _buildDashboardCard(
                icon: Icons.school_rounded,
                label: 'Switch School',
                color: const Color(0xFF64748B),
                bgColor: const Color(0xFFF1F5F9),
                onTap: _handleLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Individual clean modern dashboard tile
  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(icon, size: 22, color: color),
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom navigation bar with modern styling
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.cardWhite,
        selectedItemColor: AppColors.primaryBlue,
        unselectedItemColor: AppColors.textSecondary,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Students',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.how_to_reg_outlined),
            activeIcon: Icon(Icons.how_to_reg_rounded),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_rounded),
            activeIcon: Icon(Icons.menu_open_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
