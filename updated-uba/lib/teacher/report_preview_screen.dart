import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../theme/app_colors.dart';
import 'excel_preview_screen.dart';

/// Report Preview Screen
///
/// Displays a preview of the generated Excel attendance report with options to:
/// - View the Excel file
/// - Share the Excel file
/// - Close the preview (X button)
///
/// This screen appears after the attendance report is successfully generated.
class ReportPreviewScreen extends StatefulWidget {
  final String reportFilePath;
  final String className;
  final DateTime reportDate;

  const ReportPreviewScreen({
    super.key,
    required this.reportFilePath,
    required this.className,
    required this.reportDate,
  });

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  late String _fileName;

  @override
  void initState() {
    super.initState();
    _fileName = _extractFileName(widget.reportFilePath);
  }

  /// Extracts file name from full path
  String _extractFileName(String path) {
    return path.split(Platform.pathSeparator).last;
  }

  /// Formats date for display
  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  /// Gets file size in readable format
  Future<String> _getFileSizeString() async {
    try {
      final file = File(widget.reportFilePath);
      final sizeInBytes = await file.length();
      if (sizeInBytes < 1024) {
        return '$sizeInBytes B';
      } else if (sizeInBytes < 1024 * 1024) {
        return '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Opens the Excel file for viewing
  void _viewExcelFile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ExcelPreviewScreen(filePath: widget.reportFilePath),
      ),
    );
  }

  /// Shares the Excel file
  Future<void> _shareExcelFile() async {
    try {
      await Share.shareXFiles(
        [XFile(widget.reportFilePath)],
        text: 'Attendance Report - ${widget.className}',
        subject: 'Attendance Report ${_formatDate(widget.reportDate)}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Attendance Report Generated'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 60,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 24),

              // Success Message
              Text(
                'Report Generated Successfully!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // File Details Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cardShadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      icon: Icons.school,
                      label: 'Class:',
                      value: widget.className,
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date:',
                      value: _formatDate(widget.reportDate),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      icon: Icons.description,
                      label: 'File Name:',
                      value: _fileName,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<String>(
                      future: _getFileSizeString(),
                      builder: (context, snapshot) {
                        final size = snapshot.data ?? 'Loading...';
                        return _buildDetailRow(
                          icon: Icons.storage,
                          label: 'File Size:',
                          value: size,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // View Button
                  ElevatedButton.icon(
                    onPressed: _viewExcelFile,
                    icon: const Icon(Icons.visibility),
                    label: const Text(
                      'View Excel Sheet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Share Button
                  ElevatedButton.icon(
                    onPressed: _shareExcelFile,
                    icon: const Icon(Icons.share),
                    label: const Text(
                      'Share Excel Sheet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: AppColors.textWhite,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Close Button
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: AppColors.textSecondary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a detail row with icon, label, and value
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
