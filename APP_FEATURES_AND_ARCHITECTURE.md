# UBA School Management App - Features and Architecture

> **Purpose**: Living project document based on code inspection on 2026-10-18.
> Status labels: Verified | Partially verified | Not implemented | Needs confirmation

## 1. Project Overview

Package name idya_sathi, version 1.1.1+5. Flutter/Dart school-management portal for the
Unnat Bharat Abhiyan (UBA) programme. Supports 3 schools (A, B, C), 2 roles (Teacher/Student),
and academic-management workflows. Flutter SDK ^3.8.0.

## 2. User Roles and Permissions

### 2.1 School Selection (Verified)

| Code | Name     | Teacher email        |
|------|----------|----------------------|
| A    | School A | schoola@gmail.com    |
| B    | School B | schoolb@gmail.com    |
| C    | School C | schoolc@gmail.com    |

Source: lib/constants/app_constants.dart

> SECURITY NOTE: Teacher passwords are hardcoded in app_constants.dart.
> See SECURITY_AND_DATA_ISOLATION.md for severity assessment.

Each school maps to a separate Firebase project (physical tenant isolation).

### 2.2 Roles (Verified)

| Role    | Authentication              | Self-register? |
|---------|-----------------------------|----------------|
| Teacher | Fixed email/password/school | No             |
| Student | Email/password via teacher  | Teacher only   |
| Admin   | Not implemented             | N/A            |

Role selection in UI is navigation-only; not enforced server-side via Custom Claims or backend rules.

## 3. Feature Inventory

### 3.1 Student Registration (Verified)
File: lib/student_registration_page.dart

Required fields: Student Name, Email, Password, Confirm Password, Class (1-12), Roll Number
Optional fields: Father's Name, Gender, DOB, Mobile, Date of Admission, Previous %, Address, Parent's Mobile

CRITICAL SECURITY ISSUE: registerStudent calls auth.createUserWithEmailAndPassword which signs
in the new student in the Firebase Auth instance - this REPLACES the teacher session.

### 3.2 Teacher Dashboard (Verified)
File: lib/teacher/teacherdashboard_screen.dart

Loads total student count from Firestore. Quick actions: Student Details, Attendance, Report,
Announcements, Study Material (PLACEHOLDER - shows SnackBar), Results (PLACEHOLDER - shows SnackBar),
School Updates, Switch School. Notifications: bell icon is DECORATIVE only.

### 3.3 Student Directory (Verified)
File: lib/teacher/students_list_screen.dart
Real-time Firestore stream, schoolCode-filtered, client-side name/email search.

### 3.4 Student Details (Verified)
File: lib/teacher/student_details_screen.dart
Full profile view/edit. Email is read-only. schoolCode immutable via Firestore rules.

### 3.5 Attendance Marking (Verified)
File: lib/teacher/attendance_screen.dart

Firestore structure:
- attendance_records/{studentName_classId_date}: studentId, rollNumber, studentName, className,
  date(Timestamp), status("Present"/"Absent"), schoolCode, createdAt
- attendance_sessions/{classId_date}: className, date, totalStudents, presentCount, absentCount,
  schoolCode, createdAt, updatedAt

Features: class selector, date picker, present/absent toggle, duplicate prevention via session check,
batch write. Known issue: stats card uses _attendanceMap.length vs _studentList.length for "Total".

### 3.6 Attendance Reports and Excel (Verified)
Files: lib/teacher/attendance_report_screen.dart, attendance_report_service.dart,
excel_preview_screen.dart, report_preview_screen.dart, file_saver/
Uses 'excel' package, shares via share_plus, writes to path_provider temp dir.

### 3.7 Study Material (Not implemented)
Dashboard card shows "coming soon" SnackBar.

### 3.8 Results (Not implemented)
Dashboard card shows "coming soon" SnackBar.

### 3.9 Announcements (Verified)
File: lib/teacher/announcement_screen.dart
Fields: title, message, targetClass (all/1-12), optional date/time.
Collection: announcements. Real-time StreamBuilder filtered by schoolCode. Delete with confirmation.

### 3.10 School Updates (Verified)
File: lib/teacher/svpcet_updates_screen.dart
Fields: title, message, optional date/time. Collection: svpcet_updates. Distinct from announcements.

### 3.11 More Menu (Verified)
File: lib/common/more_menu_page.dart
Items: About Us, Contact Us, Privacy Policy (external URL), Logout (with confirmation).

### 3.12 About Us (Verified)
File: lib/common/about_us_screen.dart
Institution: SVPCET, St. Vincent Pallotti College of Engineering and Technology, Nagpur (est 2004, NAAC A).
Department: Information Technology.
Mentor: Dr. Priti Uparkar
Developers: 1.Archit Kanadkhedkar 2.Harshal Mendhule 3.Gauri Thakre 4.Anshu Bongade 5.Divyanshu Nikhare

### 3.13 Contact Us (Verified)
File: lib/common/contact_us_screen.dart
Hours: 9:00 a.m to 5:00 p.m. Email: it@stvincentngp.edu.in (mailto:)
Phones (Developer 1-5): 8625892362/9370324653/8766453345/9860725467/7385065507
NOTE: Uses deprecated canLaunch/launch - should migrate to canLaunchUrl/launchUrl.

### 3.14 Notifications (Partially verified)
Bell icon in dashboard. Static SnackBar only. No FCM or local notifications.

### 3.15 Student Dashboard (Verified)
File: lib/student/studentdashboard_screen.dart
Features: profile, announcements (read-only), school updates (read-only), transcript.

## 4. Repository Structure (Verified)

lib/
  main.dart
  school_selection_page.dart
  role_selection_page.dart
  login_page.dart
  student_registration_page.dart
  firestore_service.dart
  firebase_options.dart
  constants/app_constants.dart
  theme/app_colors.dart, app_theme.dart
  services/auth_service.dart, firebase_initialization_service.dart
  common/about_us_screen.dart, contact_us_screen.dart, more_menu_page.dart
  teacher/ (dashboard, students list, student details, attendance, reports, announcements, updates...)
  student/ (dashboard, profile, announcements, updates, transcript)
assets/dashboard/, drawer/, team/, logo/
firestore.rules, firebase.json, pubspec.yaml

## 5. Navigation and State Management (Verified)

Navigation: Imperative Navigator, MaterialPageRoute. pushAndRemoveUntil for login/logout.
State: setState only. No global state management (no Provider/Riverpod/Bloc).
Back prevention: PopScope(canPop: false) on Teacher Dashboard.

## 6. Firebase Integrations (Verified)

Firebase Authentication: Email/password (Verified)
Cloud Firestore: Primary data store (Verified)
Firebase Storage: Not used
Cloud Functions: Not used
FCM: Not used

Multi-school isolation: Separate Firebase project per school. Physical separation at project level.

Firestore Collections:
- students: name, email, schoolCode, className, rollNumber, fathersName, gender, dob,
  mobileNumber, address, dateOfAdmission, previousPercentage, parentsMobileNumber,
  currentPercentage, createdAt, updatedAt
- teachers: email, schoolCode, createdAt
- attendance_records: studentId, rollNumber, studentName, className, date, status, schoolCode
- attendance_sessions: className, date, totalStudents, presentCount, absentCount, schoolCode
- announcements: title, message, date, time, schoolCode, targetClass, createdAt, timestamp
- svpcet_updates: title, message, date, time, schoolCode, createdAt, timestamp

## 7. Error Handling Summary

All major screens have: loading spinners, empty states, error SnackBars.
Forms: validate before submit, loading state prevents duplicate submission.
Attendance Report: Partially verified.

## 8. Testing Checklist (Not verified in CI)

[ ] School and role selection routes correctly
[ ] Teacher login/logout works
[ ] Student login works only in registered school
[ ] Logout clears session and navigates to SchoolSelectionPage
[ ] Student registration creates Auth user + Firestore document
[ ] Duplicate email registration fails
[ ] Student search and class filter work
[ ] Attendance counts correct and persists
[ ] Duplicate attendance rejected
[ ] Excel report generates, views, and shares
[ ] Announcements CRUD works
[ ] School updates CRUD works
[ ] More menu: About, Contact, Privacy Policy, Logout all work
[ ] Email/phone taps work on device
[ ] UI usable on small screens with keyboard open
[ ] flutter analyze passes with no errors

## 9. Maintenance Rules

- Mark items Verified/Partially verified/Not implemented/Needs confirmation
- Cite source file paths
- Never document assumptions as facts
- Never include passwords, credentials, student records, or API secrets
