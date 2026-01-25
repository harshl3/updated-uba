# Attendance Report Feature - Code Examples

## Table of Contents
1. [Basic Integration](#basic-integration)
2. [Navigation Examples](#navigation-examples)
3. [Firestore Query Examples](#firestore-query-examples)
4. [Custom Styling](#custom-styling)
5. [Advanced Usage](#advanced-usage)

---

## Basic Integration

### Minimal Setup

```dart
import 'package:flutter/material.dart';
import 'package:uba/teacher/attendance_report_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Teacher Portal')),
        body: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceReportScreen(
                  schoolCode: 'school_001',
                ),
              ),
            );
          },
          child: const Text('Generate Attendance Report'),
        ),
      ),
    );
  }
}
```

---

## Navigation Examples

### 1. From Teacher Dashboard

```dart
// In teacherdashboard_screen.dart
import 'package:uba/teacher/attendance_report_screen.dart';

class TeacherDashboard extends StatelessWidget {
  final String schoolCode;

  const TeacherDashboard({required this.schoolCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Dashboard')),
      body: ListView(
        children: [
          // Existing menu items...
          
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Attendance Reports'),
            subtitle: const Text('Generate Excel reports'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceReportScreen(
                    schoolCode: schoolCode,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 2. From Drawer Menu

```dart
// In a screen with a drawer
Drawer(
  child: ListView(
    children: [
      const DrawerHeader(
        child: Text('Menu'),
      ),
      ListTile(
        leading: const Icon(Icons.check),
        title: const Text('Mark Attendance'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(
                schoolCode: widget.schoolCode,
              ),
            ),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.file_download),
        title: const Text('Attendance Reports'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceReportScreen(
                schoolCode: widget.schoolCode,
              ),
            ),
          );
        },
      ),
    ],
  ),
)
```

### 3. Using Named Routes

```dart
// In main.dart
import 'package:uba/teacher/attendance_report_screen.dart';

MaterialApp(
  home: const MyApp(),
  routes: {
    '/attendance': (context) => AttendanceScreen(
      schoolCode: 'school_001',
    ),
    '/attendance-report': (context) => AttendanceReportScreen(
      schoolCode: 'school_001',
    ),
  },
)

// In any screen:
Navigator.pushNamed(context, '/attendance-report');
```

---

## Firestore Query Examples

### Verify Data Structure

Before using the feature, ensure your Firestore has the correct structure:

```dart
// Query to verify attendance records exist
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> verifyAttendanceRecords(String schoolCode) async {
  final firestore = FirebaseFirestore.instance;
  
  // Get all attendance records for a class
  final snapshot = await firestore
      .collection('attendance_records')
      .where('classId', isEqualTo: 'Class 5')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(
        DateTime(2026, 1, 1),
      ))
      .get();

  print('Found ${snapshot.docs.length} attendance records');
  
  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    print('Date: ${data['date']}');
    print('Student: ${data['studentName']}');
    print('Status: ${data['status']}');
  }
}
```

### Sample Data Structure

```dart
// Example document in attendance_records collection
{
  'studentName': 'Divyanshu Kumar',
  'classId': 'Class 5',
  'date': Timestamp.fromDate(DateTime(2026, 1, 15)),
  'status': true,  // Present
  'schoolCode': 'school_001'
}

// Example document in attendance_records collection
{
  'studentName': 'Aarav Singh',
  'classId': 'Class 5',
  'date': Timestamp.fromDate(DateTime(2026, 1, 15)),
  'status': false,  // Absent
  'schoolCode': 'school_001'
}
```

---

## Custom Styling

### Change Theme Colors

```dart
// Create a custom version of AttendanceReportScreen

import 'package:flutter/material.dart';
import 'package:uba/teacher/attendance_report_screen.dart';

class CustomColoredReportScreen extends StatelessWidget {
  final String schoolCode;
  static const Color primaryColor = Color(0xFF2196F3);  // Custom blue
  static const Color accentColor = Color(0xFF4CAF50);   // Custom green

  const CustomColoredReportScreen({required this.schoolCode});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: primaryColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      child: AttendanceReportScreen(schoolCode: schoolCode),
    );
  }
}
```

### Override AppBar Style

```dart
// To modify the AppBar in AttendanceReportScreen,
// you can extend the widget:

class CustomReportScreen extends StatefulWidget {
  final String schoolCode;

  const CustomReportScreen({required this.schoolCode});

  @override
  State<CustomReportScreen> createState() => _CustomReportScreenState();
}

class _CustomReportScreenState extends State<CustomReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: const Color(0xFF1565C0),  // Custom dark blue
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Add the report body here
      ),
    );
  }
}
```

---

## Advanced Usage

### 1. Extend AttendanceReportService for Custom Formatting

```dart
import 'package:excel/excel.dart';
import 'attendance_report_service.dart';

class AdvancedReportService extends AttendanceReportService {
  /// Generate report with attendance summary
  Future<String> generateReportWithSummary({
    required List<QueryDocumentSnapshot> attendanceRecords,
    required String className,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    // First, generate the basic report
    final filePath = await generateExcelReport(
      attendanceRecords: attendanceRecords,
      className: className,
      fromDate: fromDate,
      toDate: toDate,
    );

    // TODO: Add summary sheet to Excel file
    // This would require reading the file back and adding a sheet

    return filePath;
  }

  /// Generate report by student name
  Future<String> generateStudentReport({
    required String studentName,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    // Implement custom logic here
    throw UnimplementedError();
  }
}
```

### 2. Integration with Analytics

```dart
// Track report generation
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsReportScreen extends StatefulWidget {
  final String schoolCode;

  const AnalyticsReportScreen({required this.schoolCode});

  @override
  State<AnalyticsReportScreen> createState() => _AnalyticsReportScreenState();
}

class _AnalyticsReportScreenState extends State<AnalyticsReportScreen> {
  final analytics = FirebaseAnalytics.instance;

  Future<void> _generateReportWithAnalytics() async {
    try {
      // Log analytics event
      await analytics.logEvent(
        name: 'attendance_report_generated',
        parameters: {
          'class': 'Class 5',
          'date_range_days': 30,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Generate report
      // ... report generation code ...
    } catch (e) {
      // Log error
      await analytics.logEvent(
        name: 'attendance_report_failed',
        parameters: {
          'error': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AttendanceReportScreen(schoolCode: widget.schoolCode);
  }
}
```

### 3. Batch Report Generation

```dart
// Generate reports for multiple classes
import 'attendance_report_service.dart';

class BatchReportGenerator {
  final AttendanceReportService reportService;

  BatchReportGenerator({required this.reportService});

  /// Generate reports for all classes in a date range
  Future<List<String>> generateBatchReports({
    required List<String> classNames,
    required DateTime fromDate,
    required DateTime toDate,
    required FirebaseFirestore firestore,
  }) async {
    final List<String> generatedPaths = [];

    for (String className in classNames) {
      try {
        // Fetch attendance records for this class
        final snapshot = await firestore
            .collection('attendance_records')
            .where('classId', isEqualTo: className)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
            .orderBy('date', descending: false)
            .get();

        if (snapshot.docs.isNotEmpty) {
          // Generate report
          final path = await reportService.generateExcelReport(
            attendanceRecords: snapshot.docs,
            className: className,
            fromDate: fromDate,
            toDate: toDate,
          );
          generatedPaths.add(path);
        }
      } catch (e) {
        print('Error generating report for $className: $e');
      }
    }

    return generatedPaths;
  }
}
```

### 4. Export to Different Formats

```dart
// Extend to support CSV export
import 'dart:convert';

class MultiFormatReportService {
  /// Generate CSV report instead of Excel
  Future<String> generateCsvReport({
    required List<QueryDocumentSnapshot> attendanceRecords,
    required String className,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    // Build CSV content
    final StringBuffer csv = StringBuffer();
    csv.writeln('Date,Student Name,Status');

    for (var record in attendanceRecords) {
      final data = record.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final student = data['studentName'] ?? 'Unknown';
      final status = (data['status'] as bool? ?? false) ? 'P' : 'A';

      csv.writeln('$date,$student,$status');
    }

    // Save CSV file
    // Implementation would be similar to Excel generation
    
    return 'File path here';
  }
}
```

### 5. Real-time Updates

```dart
// Stream attendance records in real-time
import 'package:cloud_firestore/cloud_firestore.dart';

class RealtimeReportStream {
  /// Get attendance records as a stream
  Stream<List<QueryDocumentSnapshot>> getAttendanceStream({
    required String classId,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return FirebaseFirestore.instance
        .collection('attendance_records')
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(toDate))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  /// Update UI as records change
  StreamBuilder<List<QueryDocumentSnapshot>> buildReportStream({
    required String classId,
    required DateTime fromDate,
    required DateTime toDate,
  }) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: getAttendanceStream(
        classId: classId,
        fromDate: fromDate,
        toDate: toDate,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final records = snapshot.data!;
        return Text('Loaded ${records.length} records');
      },
    );
  }
}
```

### 6. Error Recovery and Retry Logic

```dart
// Implement retry logic for failed operations
class ResilientReportGenerator {
  final AttendanceReportService reportService;
  final int maxRetries = 3;

  ResilientReportGenerator({required this.reportService});

  /// Generate report with automatic retry
  Future<String?> generateReportWithRetry({
    required List<QueryDocumentSnapshot> attendanceRecords,
    required String className,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        return await reportService.generateExcelReport(
          attendanceRecords: attendanceRecords,
          className: className,
          fromDate: fromDate,
          toDate: toDate,
        );
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries) {
          print('Failed after $maxRetries retries: $e');
          return null;
        }
        // Wait before retry
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    return null;
  }
}
```

---

## Testing Examples

### Unit Test for Report Service

```dart
// test/attendance_report_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:uba/teacher/attendance_report_service.dart';

void main() {
  group('AttendanceReportService', () {
    late AttendanceReportService reportService;

    setUp(() {
      reportService = AttendanceReportService();
    });

    test('generateFilename returns valid filename', () {
      final filename = reportService.generateFilename(
        'Class 5',
        DateTime(2026, 1, 15),
        DateTime(2026, 1, 31),
      );

      expect(filename, contains('attendance_'));
      expect(filename, contains('.xlsx'));
    });

    test('sanitizeSheetName limits to 31 characters', () {
      final sanitized = reportService.sanitizeSheetName(
        'This is a very long class name that exceeds the Excel sheet limit',
      );

      expect(sanitized.length, lessThanOrEqualTo(31));
    });
  });
}
```

---

## Common Patterns

### Dismissible Report Confirmation

```dart
// Show confirmation before generating large reports
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Confirm Report Generation'),
    content: Text(
      'Generate report for Class 5 from 2026-01-15 to 2026-01-31?\n\n'
      'This will create an Excel file with ${recordCount} records.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          _generateReport();
        },
        child: const Text('Generate'),
      ),
    ],
  ),
);
```

### Loading Progress Indicator

```dart
// Show progress during report generation
showDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) => WillPopScope(
    onWillPop: () async => false,
    child: const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating Excel report...'),
            ],
          ),
        ),
      ),
    ),
  ),
);
```

