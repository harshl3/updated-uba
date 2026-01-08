import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../firestore_service.dart';

/// Student Details Screen - Shows complete student information
/// 
/// Teachers can view and edit student details.
/// All data is school-scoped and isolated.
class StudentDetailsScreen extends StatefulWidget {
  final String schoolCode;
  final String studentId;
  final Map<String, dynamic> studentData;

  const StudentDetailsScreen({
    super.key,
    required this.schoolCode,
    required this.studentId,
    required this.studentData,
  });

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  bool _isEditing = false;
  bool _isLoading = false;
  
  // Controllers for all fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _fathersNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _dateOfAdmissionController = TextEditingController();
  final TextEditingController _previousPercentageController = TextEditingController();
  final TextEditingController _parentsMobileNumberController = TextEditingController();
  final TextEditingController _currentPercentageController = TextEditingController();
  
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  /// Loads student data into controllers
  void _loadStudentData() {
    _nameController.text = widget.studentData['name'] ?? '';
    _emailController.text = widget.studentData['email'] ?? '';
    _classNameController.text = widget.studentData['className'] ?? '';
    _rollNumberController.text = widget.studentData['rollNumber'] ?? '';
    _fathersNameController.text = widget.studentData['fathersName'] ?? '';
    _addressController.text = widget.studentData['address'] ?? '';
    _dobController.text = widget.studentData['dob'] ?? '';
    _mobileNumberController.text = widget.studentData['mobileNumber'] ?? '';
    _dateOfAdmissionController.text = widget.studentData['dateOfAdmission'] ?? '';
    _previousPercentageController.text = widget.studentData['previousPercentage'] ?? '';
    _parentsMobileNumberController.text = widget.studentData['parentsMobileNumber'] ?? '';
    _currentPercentageController.text = widget.studentData['currentPercentage'] ?? '';
    _selectedGender = widget.studentData['gender'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _classNameController.dispose();
    _rollNumberController.dispose();
    _fathersNameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _mobileNumberController.dispose();
    _dateOfAdmissionController.dispose();
    _previousPercentageController.dispose();
    _parentsMobileNumberController.dispose();
    _currentPercentageController.dispose();
    super.dispose();
  }

  /// Saves updated student data
  Future<void> _saveStudentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestore = await FirestoreService.firestore(widget.schoolCode);
      
      await firestore.collection('students').doc(widget.studentId).update({
        'name': _nameController.text.trim(),
        'className': _classNameController.text.trim(),
        'rollNumber': _rollNumberController.text.trim(),
        'fathersName': _fathersNameController.text.trim(),
        'address': _addressController.text.trim(),
        'gender': _selectedGender ?? '',
        'dob': _dobController.text.trim(),
        'mobileNumber': _mobileNumberController.text.trim(),
        'dateOfAdmission': _dateOfAdmissionController.text.trim(),
        'previousPercentage': _previousPercentageController.text.trim(),
        'parentsMobileNumber': _parentsMobileNumberController.text.trim(),
        'currentPercentage': _currentPercentageController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student details updated successfully!'),
          backgroundColor: AppColors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  /// Shows date picker
  Future<void> _selectDate(TextEditingController controller, String label) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Student Details' : 'Student Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveStudentData,
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _loadStudentData(); // Reload original data
                });
              },
            ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundLight,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Student Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primaryBlue,
                              child: Text(
                                (_nameController.text.isNotEmpty
                                        ? _nameController.text
                                        : 'N')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : 'No Name',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.studentData['email'] ?? 'No Email',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Basic Information
                    _buildSectionTitle('Basic Information'),
                    const SizedBox(height: 8),
                    _buildEditableField(
                      label: 'Name',
                      controller: _nameController,
                      icon: Icons.person,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: widget.studentData['email'] ?? 'N/A',
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      label: 'Class Name',
                      controller: _classNameController,
                      icon: Icons.class_,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      label: 'Roll Number',
                      controller: _rollNumberController,
                      icon: Icons.numbers,
                      enabled: _isEditing,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Personal Information
                    _buildSectionTitle('Personal Information'),
                    const SizedBox(height: 8),
                    _buildEditableField(
                      label: "Father's Name",
                      controller: _fathersNameController,
                      icon: Icons.person_outline,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    if (_isEditing)
                      DropdownButtonFormField<String>(
                        value: _selectedGender?.isEmpty ?? true ? null : _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.wc),
                          filled: true,
                          fillColor: AppColors.cardWhite,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      )
                    else
                      _buildReadOnlyField(
                        label: 'Gender',
                        value: widget.studentData['gender'] ?? 'Not specified',
                        icon: Icons.wc,
                      ),
                    const SizedBox(height: 12),
                    _buildDateField(
                      label: 'Date of Birth',
                      controller: _dobController,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      label: 'Mobile Number',
                      controller: _mobileNumberController,
                      icon: Icons.phone,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      label: 'Address',
                      controller: _addressController,
                      icon: Icons.location_on,
                      enabled: _isEditing,
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Academic Information
                    _buildSectionTitle('Academic Information'),
                    const SizedBox(height: 8),
                    _buildDateField(
                      label: 'Date of Admission',
                      controller: _dateOfAdmissionController,
                      enabled: _isEditing,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      label: 'Previous Percentage',
                      controller: _previousPercentageController,
                      icon: Icons.percent,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    _buildEditableField(
                      label: 'Current Percentage',
                      controller: _currentPercentageController,
                      icon: Icons.trending_up,
                      enabled: _isEditing,
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Contact Information
                    _buildSectionTitle('Contact Information'),
                    const SizedBox(height: 8),
                    _buildEditableField(
                      label: "Parent's Mobile Number",
                      controller: _parentsMobileNumberController,
                      icon: Icons.phone_android,
                      enabled: _isEditing,
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool enabled,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Card(
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: enabled ? AppColors.cardWhite : AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return Card(
      child: TextFormField(
        controller: controller,
        readOnly: !enabled,
        enabled: enabled,
        onTap: enabled
            ? () => _selectDate(controller, label)
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          filled: true,
          fillColor: enabled ? AppColors.cardWhite : AppColors.backgroundLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}


