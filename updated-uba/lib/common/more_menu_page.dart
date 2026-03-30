import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import 'about_us_screen.dart';
import 'contact_us_screen.dart';

/// Shared "More" menu used by BOTH Teacher and Student dashboards.
///
/// - About Us -> opens AboutUsScreen
/// - Contact Us -> opens ContactUsScreen (email/phone tappable)
/// - Logout -> triggers provided callback (keeps existing logout logic intact)
///
/// NOTE: This is intentionally UI-only. It does NOT touch Firebase/Firestore.
class MoreMenuPage extends StatelessWidget {
  final String roleLabel; // e.g. "Teacher" or "Student"
  final VoidCallback onLogout;

  const MoreMenuPage({
    super.key,
    required this.roleLabel,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 12),
          _buildMenuCard(
            context,
            title: 'About Us',
            subtitle: 'App purpose, developer names, and college info',
            icon: Icons.info_outline,
            iconColor: AppColors.primaryBlue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutUsScreen()),
              );
            },
          ),
          _buildMenuCard(
            context,
            title: 'Contact Us',
            subtitle: 'Email and phone ',
            icon: Icons.contact_support_outlined,
            iconColor: AppColors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ContactUsScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            icon: Icons.logout,
            iconColor: AppColors.red,
            onTap: onLogout,
          ),
          const SizedBox(height: 8),
          // _buildQuickContactHint(context),
          const SizedBox(height: 20),
          Image.asset(
            'assets/drawer/test2.png', // Replace with your image asset path
            fit: BoxFit.cover, // Adjust the fit as needed
            height: 350, // Set the height as needed
            width: double.infinity, // Occupy full width
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_horiz,
              color: AppColors.textWhite,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$roleLabel\'s Menu',
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }

  // /// Small helper hint: if URL launcher fails on some platforms, we still allow copy.
  // Widget _buildQuickContactHint(BuildContext context) {
  //   return Card(
  //     elevation: 0,
  //     color: AppColors.cardWhite,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(14),
  //       side: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.8)),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Row(
  //         children: [
  //           const Icon(Icons.tips_and_updates_outlined, color: AppColors.textSecondary),
  //           const SizedBox(width: 10),
  //           const Expanded(
  //             child: Text(
  //               'Tip: If email/phone cannot open, tap to copy from Contact Us.',
  //               style: TextStyle(color: AppColors.textSecondary),
  //             ),
  //           ),
  //           TextButton(
  //             onPressed: () async {
  //               // A tiny, safe “smoke test” for mailto support.
  //               final uri = Uri(scheme: 'mailto', path: 'example@example.com');
  //               final ok = await canLaunchUrl(uri);
  //               if (!context.mounted) return;
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text(ok
  //                       ? 'Email links supported on this device.'
  //                       : 'Email links may not be supported.'),
  //                 ),
  //               );
  //             },
  //             child: const Text('Test'),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  /// Shared helper for copying text (used by ContactUsScreen too).
  static Future<void> copyToClipboard(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $value')),
    );
  }
}

