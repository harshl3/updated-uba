import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student/studentdashboard_screen.dart';
import 'teacher/teacherdashboard_screen.dart';
import 'constants/app_constants.dart';
import 'services/auth_service.dart';
import 'theme/app_colors.dart';

/// Login page for both teachers and students.
/// 
/// Teachers: Use fixed credentials per school (no signup allowed)
/// Students: Use credentials provided by their teacher during registration
class LoginPage extends StatefulWidget {
  final String schoolCode;
  final String role;

  const LoginPage({super.key, required this.schoolCode, required this.role});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  /// Handles login for both teachers and students using Firebase Auth.
  /// 
  /// Teachers: Validates against fixed credentials per school
  /// Students: Validates against Firebase Auth and verifies school access
  Future<void> _handleLogin() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential? userCredential;

      if (widget.role == AppConstants.roleTeacher) {
        // Teacher login with fixed credentials
        userCredential = await AuthService.loginTeacher(
          schoolCode: widget.schoolCode,
          email: email,
          password: password,
        );
      } else {
        // Student login with Firebase Auth
        userCredential = await AuthService.loginStudent(
          schoolCode: widget.schoolCode,
          email: email,
          password: password,
        );
      }

      if (!mounted) return;

      final user = userCredential.user;
      if (user != null) {
        // Login successful - navigate to appropriate dashboard based on role
        if (widget.role == AppConstants.roleTeacher) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDashboardScreen(
                schoolCode: widget.schoolCode,
                email: email,
                userId: user.uid,
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => StudentDashboardScreen(
                schoolCode: widget.schoolCode,
                email: email,
                userId: user.uid,
              ),
            ),
          );
        }
      } else {
        throw AuthException('Login failed: No user returned');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.red,
            duration: AppConstants.snackbarDurationLong,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.textWhite,
              onPressed: () {},
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
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

  @override
  void initState() {
    super.initState();
    // Email field is now editable for teachers - no pre-filling
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTeacher = widget.role == AppConstants.roleTeacher;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.role.toUpperCase()} Login"),
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // School info card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            isTeacher ? Icons.school : Icons.person,
                            size: 48,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'School ${widget.schoolCode}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                          if (isTeacher) ...[
                            const SizedBox(height: 4),
                            const Text(
                              'Fixed Credentials',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Email field
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      hintText: isTeacher
                          ? "Enter teacher email"
                          : "Enter your email",
                      prefixIcon: const Icon(Icons.email),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Password field
                  TextFormField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintText: isTeacher ? "Enter teacher password" : "Enter your password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
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
                              "Login",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  if (isTeacher) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Note: Teacher accounts use fixed credentials.\nNo signup is allowed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
