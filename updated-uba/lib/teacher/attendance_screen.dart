import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';

/// Attendance Screen
///
/// Allows teachers to mark daily attendance for all students of a selected class.
/// Features:
/// - Dynamic class selection from Firestore (Class 1 to Class 10)
/// - Dynamic student loading based on selected class
/// - Date picker (default: today)
/// - Student list with present/absent toggles
/// - Firestore integration for attendance records
/// - Duplicate submission prevention
/// - Summary statistics (present/absent counts)
///
/// Firestore Structure:
/// - students collection:
///   - Fields: studentName (or 'name'), classId (or 'className'), schoolCode
/// - attendance_records: One document per student per day (LOGIC 2 - FLAT RECORDS)
///   - Document ID: "studentName_classId_date" (e.g., "Divyanshu_Class 5_2026-01-22")
///   - Fields: studentName, classId, date (Timestamp), status (Boolean)
/// - attendance_sessions: One document per class per day (CLASS SUMMARY)
///   - Document ID: "classId_date" (e.g., "Class 5_2026-01-22")
///   - Fields: classId, date (Timestamp), totalStudents, presentCount, absentCount
class AttendanceScreen extends StatefulWidget {
  final String schoolCode;

  const AttendanceScreen({super.key, required this.schoolCode});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

// Student data class to store roll number with attendance
class StudentAttendance {
  final String studentId;
  final String name;
  final int rollNumber;
  bool isPresent;

  StudentAttendance({
    required this.studentId,
    required this.name,
    required this.rollNumber,
    this.isPresent = true,
  });
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Selected class (e.g., "Class 1", "Class 5", etc.)
  String? _selectedClass;

  // Selected date (default: today)
  DateTime _selectedDate = DateTime.now();

  // Student list with roll numbers and attendance status
  List<StudentAttendance> _studentList = [];

  // Backward compatibility: attendance map for lookup
  Map<String, bool> _attendanceMap = {};

  // Available classes fetched from Firestore
  List<String> _availableClasses = [];

  // Loading states
  bool _isLoadingClasses = true;
  bool _isLoadingStudents = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Load available classes on screen load
    _loadAvailableClasses();
  }

  /// Fetches available classes from Firestore
  ///
  /// Shows all classes from "Class 1" to "Class 10" by default
  /// Also includes any additional classes found in the students collection
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

        // Extract unique class names from students (className field)
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
              // Already in "Class X" format
              uniqueClasses.add(normalizedClass);
            } else if (normalizedClass.startsWith('Class')) {
              // "Class1", "Class2" format - add space
              final numStr = normalizedClass.replaceAll('Class', '').trim();
              final num = int.tryParse(numStr);
              if (num != null && num >= 1 && num <= 10) {
                uniqueClasses.add('Class $num');
              }
            } else {
              // Just a number like "1", "2", etc.
              final num = int.tryParse(normalizedClass);
              if (num != null && num >= 1 && num <= 10) {
                uniqueClasses.add('Class $num');
              } else if (num == null && normalizedClass.isNotEmpty) {
                // Custom class name (not a number)
                uniqueClasses.add(normalizedClass);
              }
            }
          }
        }
      } catch (e) {
        // If fetching students fails, still show default classes
        print('Warning: Could not fetch students to find classes: $e');
      }

      // Sort classes: Class 1, Class 2, ..., Class 10, then any custom classes
      final sortedClasses = uniqueClasses.toList()
        ..sort((a, b) {
          // Extract numbers for numeric sorting
          final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;
          final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 999;

          // If both are numbers, sort numerically
          if (numA != 999 && numB != 999) {
            return numA.compareTo(numB);
          }
          // If one is a number, it comes first
          if (numA != 999) return -1;
          if (numB != 999) return 1;
          // Both are custom classes, sort alphabetically
          return a.compareTo(b);
        });

      if (mounted) {
        setState(() {
          _availableClasses = sortedClasses;
          _isLoadingClasses = false;

          // Auto-select first class if available
          if (_availableClasses.isNotEmpty && _selectedClass == null) {
            _selectedClass = _availableClasses.first;
            _loadStudentsForClass(_selectedClass!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load classes: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  /// Loads students for the selected class from Firestore
  ///
  /// Queries students collection where className == selectedClass
  /// Fetches roll numbers and sorts by roll number
  /// Initializes attendance with all students marked as Present (default)
  Future<void> _loadStudentsForClass(String classId) async {
    if (classId.isEmpty) {
      setState(() {
        _studentList = [];
        _attendanceMap = {};
      });
      return;
    }

    setState(() {
      _isLoadingStudents = true;
      _studentList = [];
      _attendanceMap = {};
    });

    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);

      // Fetch students for this class
      // Query with exact match first
      QuerySnapshot studentsSnapshot = await firestore
          .collection('students')
          .where('schoolCode', isEqualTo: widget.schoolCode)
          .where('className', isEqualTo: classId)
          .get();

      // If no results, try alternative formats
      if (studentsSnapshot.docs.isEmpty) {
        // Try without "Class " prefix (e.g., "1" instead of "Class 1")
        final classNum = classId.replaceAll('Class ', '').trim();
        if (classNum.isNotEmpty) {
          try {
            studentsSnapshot = await firestore
                .collection('students')
                .where('schoolCode', isEqualTo: widget.schoolCode)
                .where('className', isEqualTo: classNum)
                .get();
          } catch (e) {
            // If that also fails, just use empty result
          }
        }
      }

      final List<StudentAttendance> studentList = [];

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final studentName =
            data['name'] as String? ??
            data['studentName'] as String? ??
            'Unknown';

        if (studentName.isNotEmpty) {
          // Get roll number from Firestore, default to 0 if not found
          final rollNumberStr = data['rollNumber'] as String? ?? '0';
          final rollNumber = int.tryParse(rollNumberStr.trim()) ?? 0;

          final student = StudentAttendance(
            studentId: doc.id,
            name: studentName,
            rollNumber: rollNumber,
            isPresent: true,
          );

          studentList.add(student);
          _attendanceMap[studentName] = true;
        }
      }

      // Sort students by roll number (ascending)
      studentList.sort((a, b) => a.rollNumber.compareTo(b.rollNumber));

      if (mounted) {
        setState(() {
          _studentList = studentList;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load students: ${e.toString()}'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  /// Handles class selection change
  void _onClassChanged(String? newClass) {
    if (newClass != null && newClass != _selectedClass) {
      setState(() {
        _selectedClass = newClass;
      });
      // Load students for the newly selected class
      _loadStudentsForClass(newClass);
    }
  }

  /// Shows date picker and updates selected date
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: AppColors.textWhite,
              surface: AppColors.cardWhite,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Formats date as YYYY-MM-DD for document ID
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Formats date for display
  String _formatDateDisplay(DateTime date) {
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

  /// Calculates present count
  int get _presentCount {
    return _studentList.where((student) => student.isPresent).length;
  }

  /// Calculates absent count
  int get _absentCount {
    return _studentList.where((student) => !student.isPresent).length;
  }

  /// Checks if attendance has already been marked for this class and date
  ///
  /// Prevents duplicate marking by checking attendance_sessions collection
  Future<bool> _isAttendanceAlreadyMarked() async {
    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);
      final dateString = _formatDate(_selectedDate);
      final sessionDocId = '${_selectedClass}_$dateString';

      final sessionDoc = await firestore
          .collection('attendance_sessions')
          .doc(sessionDocId)
          .get();

      return sessionDoc.exists;
    } catch (e) {
      // If error checking, allow submission (better to allow than block)
      return false;
    }
  }

  /// Saves attendance to Firestore
  ///
  /// Logic 2: Flat records approach
  /// - One document per student per day in attendance_records
  /// - One document per class per day in attendance_sessions
  /// - Old attendance_records are never overwritten
  /// - attendance_sessions can be overwritten (as per requirement)
  /// - Prevents duplicate marking for the same class and date
  Future<void> _submitAttendance() async {
    if (_selectedClass == null || _selectedClass!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a class'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (_attendanceMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No students to mark attendance for'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    // Check if attendance already marked for this class and date
    final alreadyMarked = await _isAttendanceAlreadyMarked();
    if (alreadyMarked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance already marked for this class today'),
          backgroundColor: AppColors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get Firestore instance for this school
      final firestore = await FirestoreService.firestore(widget.schoolCode);

      // Format date for document IDs
      final dateString = _formatDate(_selectedDate);
      final dateTimestamp = Timestamp.fromDate(_selectedDate);

      // Batch write for better performance
      final batch = firestore.batch();

      // Save individual student attendance records with all required fields
      // Document ID format: "studentName_classId_date"
      // Use set() to control document IDs (not add())
      for (var student in _studentList) {
        final isPresent = student.isPresent;
        final docId = '${student.name}_${_selectedClass}_$dateString';

        // Check if document already exists (to prevent overwriting old records)
        final docRef = firestore.collection('attendance_records').doc(docId);
        final docSnapshot = await docRef.get();

        if (!docSnapshot.exists) {
          // Only create if document doesn't exist (never overwrite old records)
          batch.set(docRef, {
            'studentId': docId, // Unique identifier
            'rollNumber': student.rollNumber,
            'studentName': student.name,
            'className': _selectedClass,
            'date': dateTimestamp,
            'status': isPresent
                ? 'Present'
                : 'Absent', // String format: "Present" or "Absent"
            'schoolCode': widget.schoolCode,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Save class summary in attendance_sessions
      // Document ID format: "classId_date"
      // This can be overwritten (as per requirement: "Create / overwrite")
      final sessionDocId = '${_selectedClass}_$dateString';
      final sessionDocRef = firestore
          .collection('attendance_sessions')
          .doc(sessionDocId);

      // Use set() to create or overwrite the attendance session
      batch.set(sessionDocRef, {
        'className': _selectedClass,
        'date': dateTimestamp,
        'totalStudents': _studentList.length,
        'presentCount': _presentCount,
        'absentCount': _absentCount,
        'schoolCode': widget.schoolCode, // Add school code for filtering
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Commit batch write
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Attendance marked successfully!\nPresent: $_presentCount | Absent: $_absentCount',
            ),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save attendance: ${e.toString()}'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: _isLoadingClasses
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header Card with Class and Date Selection
                _buildHeaderCard(),

                // Statistics Card
                _buildStatisticsCard(),

                // Student List
                Expanded(child: _buildStudentList()),

                // Submit Button
                _buildSubmitButton(),
              ],
            ),
    );
  }

  /// Builds header card with class dropdown and date picker
  Widget _buildHeaderCard() {
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
      clipBehavior: Clip.none, // Allow dropdown menu to overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class Selection Dropdown
          Row(
            children: [
              const Icon(Icons.class_, color: AppColors.textWhite, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Class:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.none, // Allow dropdown menu to overflow
                    child: DropdownButton<String>(
                      value: _selectedClass,
                      isExpanded: true,
                      underline: const SizedBox(), // Remove default underline
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: AppColors.primaryBlue,
                      ),
                      iconSize: 28,
                      dropdownColor: AppColors.cardWhite,
                      menuMaxHeight: 300,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      hint: _availableClasses.isEmpty
                          ? const Text(
                              'No classes available',
                              style: TextStyle(color: AppColors.textSecondary),
                            )
                          : null,
                      items: _availableClasses.map((String classId) {
                        return DropdownMenuItem<String>(
                          value: classId,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              classId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _availableClasses.isEmpty
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                _onClassChanged(newValue);
                              }
                            },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Selection
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: AppColors.textWhite,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Date:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDateDisplay(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Icon(
                          Icons.calendar_month,
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds statistics card showing present/absent counts
  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            icon: Icons.check_circle,
            label: 'Present',
            value: _presentCount.toString(),
            color: AppColors.green,
            total: _attendanceMap.length,
          ),
          _buildStatItem(
            icon: Icons.cancel,
            label: 'Absent',
            value: _absentCount.toString(),
            color: AppColors.red,
            total: _attendanceMap.length,
          ),
          _buildStatItem(
            icon: Icons.people,
            label: 'Total',
            value: _attendanceMap.length.toString(),
            color: AppColors.primaryBlue,
            total: _attendanceMap.length,
          ),
        ],
      ),
    );
  }

  /// Builds individual stat item - compact version
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int total,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 26, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Builds scrollable list of students with single toggle attendance button
  ///
  /// Each student is displayed in a Card with:
  /// - Roll number (left side)
  /// - Student name (center)
  /// - Single toggle button (right side, trailing)
  ///   - Green (Present) - default state
  ///   - Red (Absent) - after first toggle
  ///   - Toggle between states on tap
  Widget _buildStudentList() {
    // Show loading indicator while loading students
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state if no students
    if (_attendanceMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedClass == null
                  ? 'Please select a class'
                  : 'No students found in ${_selectedClass}',
              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _studentList.length,
      itemBuilder: (context, index) {
        final student = _studentList[index];
        final isPresent = student.isPresent;

        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 300),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Roll Number
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${student.rollNumber}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Student Name
                  Expanded(
                    child: Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Single Toggle Button (Trailing)
                  _buildSingleToggleButton(
                    isPresent: isPresent,
                    onTap: () => _toggleAttendanceStudent(index),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds a single toggle button that switches between Present (green) and Absent (red)
  ///
  /// - Text: "Present" or "Absent"
  /// - Default state: Present (light green with dark green text)
  /// - Tapping toggles to Absent (light red with dark red text)
  /// - Same shape, size, and smooth shadow throughout
  /// - Trailing-aligned (right-hand side)
  /// - Smooth animation while toggling
  Widget _buildSingleToggleButton({
    required bool isPresent,
    required VoidCallback onTap,
  }) {
    // Colors for Present state
    final presentBg = const Color(0xFFC8E6C9); // Light green
    final presentText = const Color(0xFF2E7D32); // Dark green

    // Colors for Absent state
    final absentBg = const Color(0xFFFFCDD2); // Light red
    final absentText = const Color(0xFFC62828); // Dark red

    final backgroundColor = isPresent ? presentBg : absentBg;
    final textColor = isPresent ? presentText : absentText;
    final buttonText = isPresent ? 'Present' : 'Absent';

    return Material(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: (isPresent ? presentText : absentText).withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            buttonText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  /// Toggles attendance between Present and Absent for a specific student by index
  void _toggleAttendanceStudent(int index) {
    if (index >= 0 && index < _studentList.length) {
      setState(() {
        _studentList[index].isPresent = !_studentList[index].isPresent;
        // Also update backward compatibility map
        _attendanceMap[_studentList[index].name] =
            _studentList[index].isPresent;
      });
    }
  }

  /// Builds submit button at the bottom with clean design (no white container)
  Widget _buildSubmitButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      color: AppColors.backgroundLight,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitAttendance,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textWhite,
                      ),
                    ),
                  )
                : const Icon(Icons.save, size: 24),
            label: Text(
              _isSubmitting ? 'Saving...' : 'Submit Attendance',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.textWhite,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
