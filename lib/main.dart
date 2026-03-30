import 'package:flutter/material.dart';
import 'school_selection_page.dart';
import 'theme/app_theme.dart';

/// Main entry point of the application.
/// 
/// Initializes Flutter bindings and sets up the app with the custom theme.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

/// Root widget of the application.
/// 
/// Applies the custom theme and sets up the initial route.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'School Management App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Apply custom theme
      home: const SchoolSelectionPage(),
    );
  }
}
