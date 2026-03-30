import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'school_selection_page.dart';
import 'theme/app_theme.dart';

/// Main entry point of the application.
///
/// Initializes Flutter bindings and Firebase before running the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Initialize Firebase (VERY IMPORTANT)
  await Firebase.initializeApp();

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
      theme: AppTheme.lightTheme,
      home: const SchoolSelectionPage(),
    );
  }
}