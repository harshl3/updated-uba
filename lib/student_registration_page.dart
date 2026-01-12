import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'constants/app_constants.dart';
import 'theme/app_colors.dart';

/// Student Registration Page - Only accessible by teachers.
/// 
/// Teachers can register new students for their own school only.
/// Includes extended fields: father's name, address, gender, DOB, mobile, etc.
/// All extended fields are optional.
class StudentRegistrationPage extends StatefulWidget {
  final String schoolCode;

  const StudentRegistrationPage({
    super.key,
    required this.schoolCode,
  });

  @override
  State<StudentRegistrationPage> createState() => _StudentRegistrationPageState();
}

class _StudentRegistrationPageState extends State<StudentRegistrationPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Required fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Required fields - Class and Roll Number
  String? _selectedClass; // Class dropdown value (1-12)
  final TextEditingController _rollNumberController = TextEditingController();
  
  // Extended optional fields
  final TextEditingController _fathersNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _dateOfAdmissionController = TextEditingController();
  final TextEditingController _previousPercentageController = TextEditingController();
  final TextEditingController _parentsMobileNumberController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedGender; // Gender dropdown value

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _rollNumberController.dispose();
    _fathersNameController.dispose();
    _addressController.dispose();
    _dobController.dispose();
    _mobileNumberController.dispose();
    _dateOfAdmissionController.dispose();
    _previousPercentageController.dispose();
    _parentsMobileNumberController.dispose();
    super.dispose();
  }

  /// Handles student registration with all fields.
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.registerStudent(
        schoolCode: widget.schoolCode,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: _nameController.text.trim(),
        className: _selectedClass ?? '', // Required field
        rollNumber: _rollNumberController.text.trim(), // Required field
        fathersName: _fathersNameController.text.trim().isNotEmpty 
            ? _fathersNameController.text.trim() 
            : null,
        address: _addressController.text.trim().isNotEmpty 
            ? _addressController.text.trim() 
            : null,
        gender: _selectedGender,
        dob: _dobController.text.trim().isNotEmpty 
            ? _dobController.text.trim() 
            : null,
        mobileNumber: _mobileNumberController.text.trim().isNotEmpty 
            ? _mobileNumberController.text.trim() 
            : null,
        dateOfAdmission: _dateOfAdmissionController.text.trim().isNotEmpty 
            ? _dateOfAdmissionController.text.trim() 
            : null,
        previousPercentage: _previousPercentageController.text.trim().isNotEmpty 
            ? _previousPercentageController.text.trim() 
            : null,
        parentsMobileNumber: _parentsMobileNumberController.text.trim().isNotEmpty 
            ? _parentsMobileNumberController.text.trim() 
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student "${_nameController.text.trim()}" registered successfully!'),
          backgroundColor: AppColors.green,
          duration: AppConstants.snackbarDurationLong,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _rollNumberController.clear();
      _fathersNameController.clear();
      _addressController.clear();
      _dobController.clear();
      _mobileNumberController.clear();
      _dateOfAdmissionController.clear();
      _previousPercentageController.clear();
      _parentsMobileNumberController.clear();
      setState(() {
        _selectedGender = null;
        _selectedClass = null;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          duration: AppConstants.snackbarDurationLong,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: AppColors.red,
          duration: AppConstants.snackbarDurationLong,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Shows date picker for DOB
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
        title: const Text('Register New Student'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.person_add,
                          size: 48,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'School ${widget.schoolCode}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Register New Student',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Required Fields Section
                const Text(
                  'Required Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name
                _buildTextField(
                  controller: _nameController,
                  label: 'Student Name *',
                  hint: 'Enter full name',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Student name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email *',
                  hint: 'student@example.com',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password
                _buildPasswordField(
                  controller: _passwordController,
                  label: 'Password *',
                  hint: 'Minimum 6 characters',
                  obscureText: _obscurePassword,
                  onToggle: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password *',
                  hint: 'Re-enter password',
                  obscureText: _obscureConfirmPassword,
                  onToggle: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Class Dropdown (Required)
                DropdownButtonFormField<String>(
                  value: _selectedClass,
                  decoration: InputDecoration(
                    labelText: 'Class *',
                    hintText: 'Select class',
                    prefixIcon: const Icon(Icons.class_),
                    filled: true,
                    fillColor: AppColors.cardWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                  ),
                  items: List.generate(12, (index) {
                    final classNumber = (index + 1).toString();
                    return DropdownMenuItem(
                      value: classNumber,
                      child: Text('Class $classNumber'),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedClass = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Class is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Roll Number (Required)
                _buildTextField(
                  controller: _rollNumberController,
                  label: 'Roll Number *',
                  hint: 'e.g., 001',
                  icon: Icons.numbers,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Roll number is required';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Optional Fields Section
                const Text(
                  'Additional Information (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                
                // Father's Name
                _buildTextField(
                  controller: _fathersNameController,
                  label: "Father's Name",
                  hint: 'Enter father\'s name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                
                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender',
                    hintText: 'Select gender',
                    prefixIcon: const Icon(Icons.wc),
                    filled: true,
                    fillColor: AppColors.cardWhite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
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
                ),
                const SizedBox(height: 16),
                
                // Date of Birth
                _buildDateField(
                  controller: _dobController,
                  label: 'Date of Birth',
                  hint: 'Select date',
                  icon: Icons.calendar_today,
                  onTap: () => _selectDate(_dobController, 'Date of Birth'),
                ),
                const SizedBox(height: 16),
                
                // Mobile Number
                _buildTextField(
                  controller: _mobileNumberController,
                  label: 'Mobile Number',
                  hint: 'Enter mobile number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                
                // Date of Admission
                _buildDateField(
                  controller: _dateOfAdmissionController,
                  label: 'Date of Admission',
                  hint: 'Select date',
                  icon: Icons.event,
                  onTap: () => _selectDate(_dateOfAdmissionController, 'Date of Admission'),
                ),
                const SizedBox(height: 16),
                
                // Previous Percentage
                _buildTextField(
                  controller: _previousPercentageController,
                  label: 'Previous Percentage',
                  hint: 'e.g., 85.5',
                  icon: Icons.percent,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                // Address
                _buildTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter address',
                  icon: Icons.location_on,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Parent's Mobile Number
                _buildTextField(
                  controller: _parentsMobileNumberController,
                  label: "Parent's Mobile Number",
                  hint: 'Enter parent\'s mobile number',
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                ),
                
                const SizedBox(height: 32),
                
                // Register button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.textWhite,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "Register Student",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Info text
                Text(
                  '* Required fields\nAll other fields are optional.\nStudent will be registered in School ${widget.schoolCode} only.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a standard text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      validator: validator,
    );
  }

  /// Builds a password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      validator: validator,
    );
  }

  /// Builds a date field with date picker
  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
      ),
    );
  }
}
