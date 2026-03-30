import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';
import 'attendance_report_service.dart';
import 'report_preview_screen.dart';

/// Attendance Report Screen
///
/// Generates downloadable Excel (.xlsx) attendance reports for selected classes
/// and a specific date. Features include:
/// - Dynamic class selection from Firestore
/// - Single date picker for attendance report
/// - Excel file generation with attendance data
/// - File sharing capability
/// - Error handling and loading states
class AttendanceReportScreen extends StatefulWidget {
  final String schoolCode;

  const AttendanceReportScreen({super.key, required this.schoolCode});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  // Selected class
  String? _selectedClass;

  // Single date selection
  DateTime? _selectedDate;

  // Available classes fetched from Firestore
  List<String> _availableClasses = [];

  // Loading and submission states
  bool _isLoadingClasses = true;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableClasses();
  }

  /// Fetches available classes from Firestore
  /// Shows default classes (Class 1 to Class 10) and any custom classes
  Future<void> _loadAvailableClasses() async {
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);

      // Start with default classes: Class 1 to Class 10
      final Set<String> uniqueClasses = {};
      for (int i = 1; i <= 10; i++) {
        uniqueClasses.add('Class $i');
      }

      // Try to fetch students to find any additional classes
      try {
        final studentsSnapshot = await firestore
            .collection('students')
            .where('schoolCode', isEqualTo: widget.schoolCode)
            .get();

        // Extract unique class names from students
        for (var doc in studentsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final className = data['className'] as String?;

          if (className != null && className.isNotEmpty) {
            // Normalize className format
            String normalizedClass = className.trim();

            // Handle different formats:
            // "Class 1", "Class1", "1", "Class 01", etc.
            if (normalizedClass.startsWith('Class ')) {
              uniqueClasses.add(normalizedClass);
            } else if (normalizedClass.startsWith('Class')) {
              final numStr = normalizedClass.replaceAll('Class', '').trim();
              final num = int.tryParse(numStr);
              if (num != null && num >= 1 && num <= 10) {
                uniqueClasses.add('Class $num');
              }
            } else {
              final num = int.tryParse(normalizedClass);
              if (num != null && num >= 1 && num <= 10) {
                uniqueClasses.add('Class $num');
              } else if (num == null && normalizedClass.isNotEmpty) {
                uniqueClasses.add(normalizedClass);
              }
            }
          }
        }
      } catch (e) {
        // If fetching students fails, still show default classes
      }

      // Sort classes: Class 1, Class 2, ..., Class 10, then custom classes
      final sortedClasses = uniqueClasses.toList()
        ..sort((a, b) {
          final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
          final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;

          if (numA != 999 && numB != 999) {
            return numA.compareTo(numB);
          }
          if (numA != 999) return -1;
          if (numB != 999) return 1;
          return a.compareTo(b);
        });

      if (mounted) {
        setState(() {
          _availableClasses = sortedClasses;
          _isLoadingClasses = false;

          // Auto-select first class
          if (_availableClasses.isNotEmpty && _selectedClass == null) {
            _selectedClass = _availableClasses.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
        _showErrorSnackBar('Failed to load classes: ${e.toString()}');
      }
    }
  }

  /// Opens date picker for single date selection
  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Validates form and generates Excel report
  /// Shows appropriate error messages if validation fails
  Future<void> _generateReport() async {
    // Validate form
    if (_selectedClass == null || _selectedClass!.isEmpty) {
      _showErrorSnackBar('Please select a class');
      return;
    }

    if (_selectedDate == null) {
      _showErrorSnackBar('Please select a date');
      return;
    }

    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);

      // First check if attendance session exists for this date and class
      final sessionId = '${_selectedClass}_${_formatDate(_selectedDate!)}';
      final sessionDoc = await firestore
          .collection('attendance_sessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        if (mounted) {
          setState(() {
            _isGeneratingReport = false;
          });
          _showErrorSnackBar(
            'Attendance not marked for this class on selected date',
          );
        }
        return;
      }
      // Query attendance records for the selected class only
      // Filter by date in code to avoid composite index requirement
      final attendanceSnapshot = await firestore
          .collection('attendance_records')
          .where('className', isEqualTo: _selectedClass)
          .get();

      // Filter records by selected date and sort by roll number (ascending)
      final startOfDay = _selectedDate!;
      final endOfDay = _selectedDate!.add(const Duration(days: 1));

      print(
        'DEBUG: Filtering records for date range: $startOfDay to $endOfDay',
      );
      print('DEBUG: Total records fetched: ${attendanceSnapshot.docs.length}');

      final sortedDocs =
          attendanceSnapshot.docs.where((doc) {
            final data = doc.data();
            final date = data['date'] as Timestamp?;
            if (date == null) {
              print('DEBUG: Record has no date field');
              return false;
            }
            final recordDate = date.toDate();
            // Check if record date is within selected date range
            final isWithinRange =
                recordDate.year == startOfDay.year &&
                recordDate.month == startOfDay.month &&
                recordDate.day == startOfDay.day;

            if (!isWithinRange) {
              print(
                'DEBUG: Record date $recordDate not matching selected date $startOfDay',
              );
            }

            return isWithinRange;
          }).toList()..sort((a, b) {
            final rollA = a.data()['rollNumber'] as int? ?? 999;
            final rollB = b.data()['rollNumber'] as int? ?? 999;
            return rollA.compareTo(rollB);
          });

      print(
        'DEBUG: After filtering: ${sortedDocs.length} records match selected date',
      );

      if (sortedDocs.isEmpty) {
        if (mounted) {
          setState(() {
            _isGeneratingReport = false;
          });
          _showErrorSnackBar('No attendance data available for selected date');
        }
        return;
      }

      // Create and save Excel file
      final reportService = AttendanceReportService();
      final filePath = await reportService.generateExcelReport(
        attendanceRecords: sortedDocs,
        className: _selectedClass!,
        reportDate: _selectedDate!,
      );

      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });

        // Show success message
        _showSuccessSnackBar('Report generated successfully!');

        // Show dialog with file path and share option
        _showReportDialog(filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
        _showErrorSnackBar('Error generating report: ${e.toString()}');
      }
    }
  }

  /// Shows dialog with generated file path and action options
  void _showReportDialog(String filePath) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Report Generated',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Attendance report saved successfully',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToReportPreview(filePath);
                        },
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Excel Sheet'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _shareFile(filePath);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Navigates to Report Preview Screen with file details using smooth transition
  void _navigateToReportPreview(String filePath) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReportPreviewScreen(
              reportFilePath: filePath,
              className: _selectedClass ?? 'Unknown',
              reportDate: _selectedDate ?? DateTime.now(),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  /// Shares the generated Excel file using share_plus
  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: 'Attendance Report');
    } catch (e) {
      _showErrorSnackBar('Error sharing file: ${e.toString()}');
    }
  }

  /// Shows error snack bar message
  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Shows success snack bar message
  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppColors.backgroundLight,
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Class Dropdown Section
                  _buildSectionTitle('Select Class'),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedClass,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedClass = value;
                        });
                      },
                      items: _availableClasses.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      underline: const SizedBox(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Date Picker Section
                  _buildSectionTitle('Select Date'),
                  const SizedBox(height: 12),
                  _buildDatePickerButton(
                    label: _selectedDate == null
                        ? 'Select Date'
                        : 'Date: ${_formatDate(_selectedDate!)}',
                    onPressed: () => _selectDate(context),
                    isSelected: _selectedDate != null,
                  ),
                  const SizedBox(height: 40),

                  // Info Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: const Text(
                            'The report will contain attendance records for the selected date with columns: Student Name, Roll Number, Attendance Status, and Date.',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Generate Report Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isGeneratingReport ||
                              _selectedClass == null ||
                              _selectedDate == null
                          ? null
                          : _generateReport,
                      icon: _isGeneratingReport
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.file_download),
                      label: Text(
                        _isGeneratingReport
                            ? 'Generating Report...'
                            : 'Generate Excel Report',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Builds section title widget with consistent styling
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Builds date picker button with improved styling
  Widget _buildDatePickerButton({
    required String label,
    required VoidCallback onPressed,
    required bool isSelected,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.calendar_today,
        color: isSelected ? AppColors.primaryBlue : Colors.grey[500],
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.textPrimary : Colors.grey[600],
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppColors.primaryBlue : Colors.grey[300]!,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Formats date to YYYY-MM-DD format
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
