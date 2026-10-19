import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

/// Contact Us Screen
///
/// Shows static contact details (emails + phone numbers) with tappable actions.
/// Design: Material 3-aligned, consistent with app design system.
/// Fixes deprecated canLaunch/launch → canLaunchUrl/launchUrl.
class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launch(BuildContext context, String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open this contact'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const email = 'it@stvincentngp.edu.in';

    const phones = [
      _ContactItem(label: 'Archit Kanadkhedkar', value: '8625892362'),
      _ContactItem(label: 'Harshal Mendhule', value: '9370324653'),
      _ContactItem(label: 'Gauri Thakre', value: '8766453345'),
      _ContactItem(label: 'Anshu Bongade', value: '9860725467'),
      _ContactItem(label: 'Divyanshu Nikhare', value: '7385065507'),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Contact Us'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 32,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Get in Touch',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Available Monday – Saturday\n9:00 AM to 5:00 PM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Body content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Email card
                  _buildSectionLabel('Email'),
                  const SizedBox(height: 10),
                  _buildContactCard(
                    context: context,
                    icon: Icons.email_rounded,
                    iconColor: AppColors.primaryBlue,
                    iconBg: AppColors.lightBlue,
                    title: 'Department Email',
                    subtitle: email,
                    url: 'mailto:$email',
                    actionLabel: 'Send Email',
                  ),
                  const SizedBox(height: 24),

                  // Phone numbers card
                  _buildSectionLabel('Phone Numbers'),
                  const SizedBox(height: 10),
                  _buildPhoneCard(context: context, phones: phones),
                  const SizedBox(height: 24),

                  // Bottom image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/drawer/test3.png',
                      fit: BoxFit.cover,
                      height: 240,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.location_city_rounded,
                            size: 64,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String url,
    required String actionLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _launch(context, url),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              foregroundColor: AppColors.primaryBlue,
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneCard({
    required BuildContext context,
    required List<_ContactItem> phones,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: phones.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Column(
            children: [
              InkWell(
                onTap: () => _launch(context, 'tel:${item.value}'),
                borderRadius: BorderRadius.vertical(
                  top: idx == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom:
                      idx == phones.length - 1 ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.greenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.phone_rounded,
                          size: 20,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.call_rounded,
                        size: 20,
                        color: AppColors.green,
                      ),
                    ],
                  ),
                ),
              ),
              if (idx < phones.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ContactItem {
  final String label;
  final String value;

  const _ContactItem({required this.label, required this.value});
}
