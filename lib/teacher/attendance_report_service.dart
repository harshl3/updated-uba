import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Service for generating Excel attendance reports
///
/// Handles the conversion of Firestore attendance records into Excel files
/// with proper formatting and organization.
class AttendanceReportService {
  /// Generates an Excel report from Firestore attendance records
  ///
  /// Parameters:
  /// - attendanceRecords: List of QueryDocumentSnapshot from Firestore
  /// - className: Name of the class (e.g., "Class 5")
  /// - reportDate: Specific date for the attendance report
  ///
  /// Returns:
  /// - Path to the generated Excel file
  ///
  /// Throws:
  /// - Exception if file creation fails
  Future<String> generateExcelReport({
    required List<QueryDocumentSnapshot> attendanceRecords,
    required String className,
    required DateTime reportDate,
  }) async {
    print(
      'DEBUG: Starting Excel generation with ${attendanceRecords.length} records',
    );

    // Create Excel workbook
    final excel = Excel.createExcel();

    // Remove default sheet and create new one with specific name
    excel.delete('Sheet1');
    final sheetName = '${_sanitizeSheetName(className)}_Attendance';
    excel.rename('Sheet1', sheetName);
    final sheet = excel[sheetName];

    // Add header row with new columns in specified order
    // 1. Roll Number, 2. Student Name, 3. Attendance Status, 4. Attendance Date
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue('Roll Number');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0))
      ..value = TextCellValue('Student Name');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0))
      ..value = TextCellValue('Attendance Status');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0))
      ..value = TextCellValue('Attendance Date');

    print('DEBUG: Header row added with new columns');

    // Add data rows using direct cell setting
    print(
      'DEBUG: Adding ${attendanceRecords.length} attendance records to Excel',
    );
    int rowIndex = 1;

    for (var record in attendanceRecords) {
      final data = record.data() as Map<String, dynamic>;

      final rollNumber = data['rollNumber'] as int? ?? 0;
      final studentName = data['studentName'] as String? ?? 'Unknown';

      // Handle both string and boolean status values for backward compatibility
      final statusValue = data['status'];
      final status = statusValue is String
          ? statusValue
          : (statusValue is bool
                ? (statusValue ? 'Present' : 'Absent')
                : 'Absent');

      final date = data['date'] as Timestamp?;
      final dateStr = date != null
          ? _formatDate(date.toDate())
          : _formatDate(reportDate);

      print(
        'DEBUG: Adding row $rowIndex - Roll: $rollNumber, Student: $studentName, Status: $status',
      );

      // Set cells with new column structure
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        ..value = IntCellValue(rollNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        ..value = TextCellValue(studentName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
        ..value = TextCellValue(status);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
        ..value = TextCellValue(dateStr);

      rowIndex++;
    }

    print('DEBUG: Total rows to save: $rowIndex');

    // Auto-fit column widths
    _autoFitColumns(sheet);

    // Save file to device storage
    final filePath = await _saveExcelFile(excel, className, reportDate);

    return filePath;
  }

  /// Auto-fits column widths and applies formatting to cells
  void _autoFitColumns(Sheet sheet) {
    // Set column widths for new column structure
    // Column A (Roll Number): narrow
    sheet.setColumnWidth(0, 15);
    // Column B (Student Name): widest
    sheet.setColumnWidth(1, 35);
    // Column C (Attendance Status): medium
    sheet.setColumnWidth(2, 20);
    // Column D (Attendance Date): medium
    sheet.setColumnWidth(3, 20);

    // Set row height for header
    sheet.setRowHeight(0, 25);

    // Apply header formatting (bold + light background)
    // Apply header style to all header cells (Roll Number, Student Name, Attendance Status, Attendance Date)
    for (int col = 0; col < 4; col++) {
      final headerCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
      );

      // Create cell style for header with bold and borders
      headerCell.cellStyle = CellStyle(
        bold: true,
        fontFamily: 'Calibri',
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }

    // Apply data cell formatting (borders and alignment)
    // Get the maximum row index with data
    int maxRow = sheet.maxRows;

    // Apply data cell styles
    for (int row = 1; row < maxRow; row++) {
      // Roll Number - center aligned
      final rollCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
      );
      rollCell.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Student Name - left aligned
      final nameCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
      );
      nameCell.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Left,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Attendance Status - center aligned
      final statusCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
      );
      statusCell.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );

      // Attendance Date - center aligned
      final dateCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
      );
      dateCell.cellStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }
  }

  /// Saves Excel file to device storage
  /// Returns the file path
  Future<String> _saveExcelFile(
    Excel excel,
    String className,
    DateTime reportDate,
  ) async {
    final directory = await getApplicationDocumentsDirectory();

    // Create filename with class name and date
    final filename = _generateFilename(className, reportDate);
    final filePath = '${directory.path}/$filename';

    try {
      print('DEBUG: Saving Excel file to: $filePath');

      // Save the Excel file to bytes
      final bytes = excel.save();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Excel save returned empty bytes');
      }

      print('DEBUG: Excel bytes generated, size: ${bytes.length} bytes');

      // Write bytes to file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      print('DEBUG: File write completed');

      // Verify file was written and has content
      final fileSize = await file.length();
      print('DEBUG: File size on disk: $fileSize bytes');

      if (fileSize == 0) {
        throw Exception('File was created but is empty');
      }

      if (!await file.exists()) {
        throw Exception('File does not exist after writing');
      }

      print('DEBUG: File verification passed');

      return filePath;
    } catch (e) {
      throw Exception('Failed to save Excel file: ${e.toString()}');
    }
  }

  /// Generates filename for the Excel report
  /// Format: Attendance_Report_Class_<ClassName>_<YYYY-MM-DD>.xlsx
  String _generateFilename(String className, DateTime reportDate) {
    final sanitizedClass = _sanitizeFilename(className);
    final dateStr = _formatDate(reportDate);

    return 'Attendance_Report_Class_${sanitizedClass}_$dateStr.xlsx';
  }

  /// Sanitizes string for use in filename
  String _sanitizeFilename(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Sanitizes string for use in Excel sheet name
  /// Excel sheet names have length limits and invalid characters
  String _sanitizeSheetName(String input) {
    // Remove invalid characters: \ / ? * [ ]
    String sanitized = input.replaceAll(RegExp(r'[\\/?*\[\]]'), '');

    // Limit to 31 characters (Excel sheet name limit)
    if (sanitized.length > 31) {
      sanitized = sanitized.substring(0, 31);
    }

    return sanitized;
  }

  /// Formats date to YYYY-MM-DD format
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
