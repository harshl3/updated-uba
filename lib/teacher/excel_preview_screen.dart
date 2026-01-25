import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import '../theme/app_colors.dart';

/// Excel Preview Screen
///
/// Displays the content of a generated Excel attendance report file
/// in a professional DataTable format with formatting support.
///
/// Features:
/// - Reads Excel file from provided file path
/// - Parses and displays all rows in a DataTable
/// - Supports scrolling (horizontal and vertical)
/// - Status formatting (P in green, A in red)
/// - Error handling for missing or corrupt files
class ExcelPreviewScreen extends StatefulWidget {
  final String filePath;

  const ExcelPreviewScreen({super.key, required this.filePath});

  @override
  State<ExcelPreviewScreen> createState() => _ExcelPreviewScreenState();
}

class _ExcelPreviewScreenState extends State<ExcelPreviewScreen> {
  late Future<ExcelData> _excelDataFuture;

  @override
  void initState() {
    super.initState();
    _excelDataFuture = _loadExcelFile();
  }

  /// Loads and parses the Excel file
  Future<ExcelData> _loadExcelFile() async {
    try {
      // Check if file exists
      final file = File(widget.filePath);
      print('DEBUG: Reading file from: ${widget.filePath}');

      if (!file.existsSync()) {
        throw Exception('File not found: ${widget.filePath}');
      }

      print('DEBUG: File exists, checking size...');
      final fileSize = await file.length();
      print('DEBUG: File size: $fileSize bytes');

      // Read Excel file bytes
      final bytes = file.readAsBytesSync();
      print('DEBUG: Bytes read: ${bytes.length} bytes');

      if (bytes.isEmpty) {
        throw Exception('Excel file is empty or corrupted');
      }

      print('DEBUG: Decoding Excel file...');
      final excel = Excel.decodeBytes(bytes);

      // Check if tables exist
      if (excel.tables.isEmpty) {
        throw Exception('No sheets found in Excel file');
      }

      print('DEBUG: Found ${excel.tables.length} sheet(s)');

      // Get first sheet
      final sheet = excel.tables.values.first;

      // Get all rows from sheet - be lenient with checking
      final List<List<Data?>> allRows = sheet.rows;

      print('DEBUG: Sheet.rows has ${allRows.length} rows');
      print('DEBUG: Sheet.maxRows = ${sheet.maxRows}');

      if (allRows.isNotEmpty) {
        print('DEBUG: First row (header) has ${allRows[0].length} cells');
      }

      // Alternative approach: use maxRows if sheet.rows is empty
      if ((allRows.isEmpty || allRows.length < 1) && sheet.maxRows > 0) {
        print('DEBUG: sheet.rows is empty, using sheet.row() method instead');

        final List<String> headers = [];

        // Get header row
        final headerRow = sheet.row(0);
        for (final cell in headerRow) {
          if (cell == null) {
            headers.add('');
          } else if (cell.value != null) {
            headers.add(cell.value.toString().trim());
          } else {
            headers.add('');
          }
        }

        print('DEBUG: Headers parsed: $headers');

        // Get data rows
        final List<List<String>> dataRows = [];
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.row(i);
          final rowData = <String>[];

          for (int j = 0; j < headers.length; j++) {
            final cell = j < row.length ? row[j] : null;
            String cellValue = '';

            if (cell != null && cell.value != null) {
              cellValue = cell.value.toString().trim();
            }

            rowData.add(cellValue);
          }

          if (rowData.any((cell) => cell.isNotEmpty)) {
            dataRows.add(rowData);
            print('DEBUG: Row $i added: $rowData');
          }
        }

        if (dataRows.isEmpty) {
          throw Exception('No data rows found in Excel');
        }

        print('DEBUG: Total data rows: ${dataRows.length}');
        return ExcelData(headers: headers, rows: dataRows);
      }

      if (allRows.isEmpty || allRows.length < 1) {
        throw Exception('Excel sheet is empty - no rows found');
      }

      // Parse header row (first row) from sheet.rows
      final headerRow = allRows[0];
      final List<String> headers = [];

      if (headerRow.isNotEmpty) {
        for (final cell in headerRow) {
          if (cell == null) {
            headers.add('');
          } else if (cell.value != null) {
            headers.add(cell.value.toString().trim());
          } else {
            headers.add('');
          }
        }
      } else {
        throw Exception('Header row is empty');
      }

      print('DEBUG: Headers from sheet.rows: $headers');

      // Parse data rows (from second row onwards)
      final List<List<String>> dataRows = [];

      for (int i = 1; i < allRows.length; i++) {
        final row = allRows[i];
        if (row.isEmpty) continue;

        final rowData = <String>[];

        for (int j = 0; j < headers.length; j++) {
          final cell = j < row.length ? row[j] : null;
          String cellValue = '';

          if (cell != null && cell.value != null) {
            cellValue = cell.value.toString().trim();
          }

          rowData.add(cellValue);
        }

        // Add row if it has at least some data
        if (rowData.any((cell) => cell.isNotEmpty)) {
          dataRows.add(rowData);
        }
      }

      if (dataRows.isEmpty) {
        throw Exception('No attendance data found in Excel sheet');
      }

      return ExcelData(headers: headers, rows: dataRows);
    } catch (e) {
      throw Exception('Error loading Excel file: ${e.toString()}');
    }
  }

  /// Returns formatted status text
  String _getStatusLabel(String status) {
    final upperStatus = status.toUpperCase().trim();
    if (upperStatus == 'P') {
      return 'Present';
    } else if (upperStatus == 'A') {
      return 'Absent';
    }
    return status;
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
      body: FutureBuilder<ExcelData>(
        future: _excelDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildErrorWidget('No data available');
          }

          final excelData = snapshot.data!;

          if (excelData.rows.isEmpty) {
            return _buildErrorWidget('No attendance records found');
          }

          return _buildDataTable(excelData);
        },
      ),
    );
  }

  /// Builds error widget
  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.red),
          const SizedBox(height: 16),
          Text(
            'Unable to open report',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.red),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  /// Builds data table widget with enhanced formatting
  Widget _buildDataTable(ExcelData excelData) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          color: AppColors.backgroundLight,
          child: DataTable(
            columnSpacing: 16,
            dataRowHeight: 50,
            headingRowHeight: 56,
            headingRowColor: MaterialStateProperty.all(AppColors.lightBlue),
            border: TableBorder(
              horizontalInside: BorderSide(
                color: AppColors.lightBlue.withOpacity(0.3),
                width: 0.5,
              ),
              bottom: BorderSide(
                color: AppColors.lightBlue.withOpacity(0.5),
                width: 1,
              ),
              top: BorderSide(
                color: AppColors.lightBlue.withOpacity(0.5),
                width: 1,
              ),
            ),
            columns: excelData.headers
                .map(
                  (header) => DataColumn(
                    label: Text(
                      header,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                )
                .toList(),
            rows: excelData.rows
                .map(
                  (rowData) => DataRow(
                    cells: List.generate(excelData.headers.length, (colIndex) {
                      final cellValue = colIndex < rowData.length
                          ? rowData[colIndex]
                          : '';

                      // Special formatting for Status column
                      if (colIndex == excelData.headers.length - 1 &&
                          excelData.headers[colIndex].toLowerCase() ==
                              'status') {
                        final isPresent = cellValue.toUpperCase().trim() == 'P';
                        final bgColor = isPresent
                            ? const Color(0xFFC8E6C9) // Light green
                            : const Color(0xFFFFCDD2); // Light red
                        final textColor = isPresent
                            ? const Color(0xFF2E7D32) // Dark green
                            : const Color(0xFFC62828); // Dark red
                        final label = _getStatusLabel(cellValue);

                        return DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: textColor.withOpacity(0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: textColor,
                              ),
                            ),
                          ),
                        );
                      }

                      // Regular cell
                      return DataCell(
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            cellValue,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

/// Data class to hold parsed Excel data
class ExcelData {
  final List<String> headers;
  final List<List<String>> rows;

  ExcelData({required this.headers, required this.rows});
}
