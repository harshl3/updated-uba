# Attendance Report Feature - Integration Guide

## Quick Start

### Step 1: Update Dependencies

The `pubspec.yaml` has already been updated with:
```yaml
excel: ^2.1.1
path_provider: ^2.1.3
share_plus: ^10.0.0
```

Run `flutter pub get` to install these packages.

### Step 2: Add Navigation to Teacher Dashboard

To make the Attendance Report feature accessible, add it to your teacher dashboard or navigation menu.

**Example: Adding to TeacherDashboard**

```dart
import 'package:uba/teacher/attendance_report_screen.dart';

// In your teacher dashboard, add a button or menu item:
ListTile(
  leading: const Icon(Icons.file_download),
  title: const Text('Attendance Reports'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceReportScreen(
          schoolCode: widget.schoolCode,
        ),
      ),
    );
  },
)
```

### Step 3: Add to Drawer/Navigation Menu

If you have a navigation drawer:

```dart
ListTile(
  leading: const Icon(Icons.assessment),
  title: const Text('Attendance Report'),
  onTap: () {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AttendanceReportScreen(
          schoolCode: schoolCode,
        ),
      ),
    );
  },
)
```

## File Structure

After integration, your `lib/teacher/` directory will contain:

```
teacher/
├── announcement_screen.dart
├── attendance_screen.dart
├── attendance_report_screen.dart      ← NEW
├── attendance_report_service.dart     ← NEW
├── class_selection_screen.dart
├── students_list_screen.dart
├── student_details_screen.dart
├── teacherdashboard_screen.dart
```

## Features Overview

### Screen: AttendanceReportScreen

**Location**: `lib/teacher/attendance_report_screen.dart`

**Entry Point**:
```dart
AttendanceReportScreen(schoolCode: 'school_code')
```

**Required Parameters**:
- `schoolCode` (String): The school code for Firestore queries

**Features**:
- ✅ Class selection dropdown (auto-populated from Firestore)
- ✅ Date range picker (From Date and To Date)
- ✅ Form validation (prevents invalid submissions)
- ✅ Excel report generation
- ✅ File sharing capability
- ✅ Error handling and user feedback
- ✅ Loading states

### Service: AttendanceReportService

**Location**: `lib/teacher/attendance_report_service.dart`

**Main Method**:
```dart
Future<String> generateExcelReport({
  required List<QueryDocumentSnapshot> attendanceRecords,
  required String className,
  required DateTime fromDate,
  required DateTime toDate,
})
```

**Returns**: File path to generated Excel file

## Firestore Data Requirements

The feature works with your existing Firestore structure:

### attendance_records collection
Required fields:
- `studentName` (String)
- `classId` (String)
- `date` (Timestamp)
- `status` (Boolean) - true for Present, false for Absent

**Note**: No changes needed to your existing attendance marking logic.

## User Workflow

```
Teacher opens app
    ↓
Navigates to "Attendance Reports"
    ↓
Selects a class
    ↓
Selects "From Date"
    ↓
Selects "To Date"
    ↓
Clicks "Generate Excel Report"
    ↓
Excel file is generated
    ↓
Success dialog shown with file path
    ↓
Teacher can share file (optional)
```

## Generated Report Format

**Sheet Name**: `<ClassName>_Attendance`

**Columns**:
1. Date (YYYY-MM-DD format)
2. Student Name
3. Status (P = Present, A = Absent)

**Example**:
```
Date       | Student Name | Status
-----------|--------------|-------
2026-01-15 | Divyanshu    | P
2026-01-15 | Aarav        | A
2026-01-16 | Divyanshu    | P
```

**Formatting**:
- Header row: Blue background, white bold text
- Data rows: Alternating white/light gray backgrounds
- All cells: Bordered
- Column widths: Optimized for readability

## File Naming

Generated files follow this pattern:
```
attendance_<classname>_<fromdate>_<todate>.xlsx
```

Example:
```
attendance_class_5_2026-01-15_2026-01-31.xlsx
```

## Error Handling

The feature handles these error cases:

| Error | Message | Resolution |
|-------|---------|-----------|
| No class selected | "Please select a class" | Select a class from dropdown |
| Missing From Date | "Please select a From Date" | Use date picker to select |
| Missing To Date | "Please select a To Date" | Use date picker to select |
| Invalid range | "From Date cannot be after To Date" | Select correct date range |
| No data found | "No attendance data available for selected range" | Check if records exist |
| Query error | "Error generating report: ..." | Check Firestore connectivity |

## Permissions Required

### Android
```xml
<!-- In AndroidManifest.xml, ensure these are present: -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

### iOS
```xml
<!-- In Info.plist, may need: -->
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to generate and share files</string>
```

## Firestore Security Rules

Ensure your Firestore rules allow reading attendance_records:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow teachers to read attendance records for their school
    match /attendance_records/{document=**} {
      allow read: if request.auth.uid != null;
      allow write: if request.auth.uid != null;
    }
    
    // Allow reading students collection
    match /students/{document=**} {
      allow read: if request.auth.uid != null;
    }
  }
}
```

## Testing the Feature

### Test Case 1: Basic Report Generation
1. Open Attendance Report screen
2. Select "Class 5"
3. Select From Date: 2026-01-15
4. Select To Date: 2026-01-31
5. Click "Generate Excel Report"
6. Verify file is created and can be opened

### Test Case 2: Date Validation
1. Select From Date: 2026-01-31
2. Select To Date: 2026-01-15
3. Click "Generate Excel Report"
4. Verify error: "From Date cannot be after To Date"

### Test Case 3: No Data Handling
1. Select a class with no attendance records
2. Select date range with no records
3. Click "Generate Excel Report"
4. Verify error: "No attendance data available for selected range"

### Test Case 4: File Sharing
1. Generate a valid report
2. Click "Share" button in success dialog
3. Verify share dialog appears
4. Select a sharing option (email, messaging, etc.)
5. Verify file is shared

## Troubleshooting

### "flutter pub get" fails
```bash
# Solution: Clean and get dependencies again
flutter clean
flutter pub get
```

### "Undefined class AttendanceReportScreen"
```dart
// Make sure to import correctly:
import 'package:uba/teacher/attendance_report_screen.dart';
```

### Excel file not created
1. Check device storage has space
2. Verify app has write permissions
3. Check Firestore has connectivity
4. Review error message in console

### File not sharing
1. Verify share_plus is installed
2. Check app has permission to access files
3. Try different sharing app
4. Check file exists at returned path

## Performance Considerations

- **Query Optimization**: Uses indexed Firestore queries for speed
- **Memory**: Loads records in batches without loading entire collection
- **File Size**: Handles large class sizes efficiently
- **UI Responsiveness**: Loading states prevent freezing

## Customization Options

### Change Primary Color
In `AttendanceReportScreen` and `AttendanceReportService`, replace:
```dart
AppColors.primaryBlue  // Replace with your color
```

### Change Column Headers
Edit in `AttendanceReportService._styleHeaderRow()`:
```dart
sheet.insertRowIterables(['Custom Date', 'Custom Name', 'Custom Status'], 0);
```

### Change Date Format
Edit in both files - search for `_formatDate()` method

### Change Status Display
In `AttendanceReportService.generateExcelReport()`:
```dart
final statusStr = status ? 'Present' : 'Absent';  // Instead of 'P'/'A'
```

## Code Maintenance

### Key Classes

1. **AttendanceReportScreen** (StatefulWidget)
   - UI layer for report generation
   - Handles user input and navigation
   - Delegates Excel generation to service

2. **AttendanceReportService** (Service class)
   - Business logic for Excel generation
   - Handles file creation and formatting
   - No UI dependencies

### Adding New Features

To add new features (e.g., summary statistics):

1. Add logic to `AttendanceReportService`
2. Call from `AttendanceReportScreen._generateReport()`
3. Update UI to display new information

## Support and Debugging

### Enable Debug Logging

Add to `AttendanceReportScreen`:
```dart
print('Selected class: $_selectedClass');
print('From Date: $_fromDate');
print('To Date: $_toDate');
```

### Check Firestore Data

```dart
// In console:
firebase.firestore().collection('attendance_records')
  .where('classId', '==', 'Class 5')
  .limit(10)
  .get()
  .then(snapshot => console.log(snapshot.docs))
```

## Next Steps

1. ✅ Update pubspec.yaml with new dependencies
2. ✅ Add AttendanceReportScreen to your navigation
3. ✅ Test with sample data
4. ✅ Configure Firestore rules if needed
5. ✅ Deploy to production

