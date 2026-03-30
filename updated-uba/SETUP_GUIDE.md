# School Management App - Setup Guide

## 📋 Overview

This Flutter app manages multiple schools with complete data isolation. Each school has its own Firebase project, ensuring teachers and students can only access their own school's data.

## 🔐 Teacher Credentials Setup

**IMPORTANT:** Teacher accounts must be manually created in Firebase Console for each school before teachers can login.

### Fixed Teacher Credentials:

- **School A**: 
  - Email: `schoola@gmail.com`
  - Password: `schoola123`

- **School B**: 
  - Email: `schoolb@gmail.com`
  - Password: `schoolb123`

- **School C**: 
  - Email: `schoolc@gmail.com`
  - Password: `schoolc123`

### Steps to Create Teacher Accounts:

1. Go to Firebase Console for each school project
2. Navigate to Authentication → Users
3. Click "Add user"
4. Enter the teacher email and password for that school
5. Click "Add user"

Repeat for all three schools (A, B, C).

## 🗄️ Firestore Setup

### Required Collections:

The app uses the following Firestore collections:

1. **`students`** - Student records with the following fields:
   - `email` (string)
   - `name` (string)
   - `schoolCode` (string) - **CRITICAL for data isolation**
   - `className` (string, optional)
   - `rollNumber` (string, optional)
   - `createdAt` (timestamp)
   - `updatedAt` (timestamp)

2. **`teachers`** - Teacher records (auto-created on first login):
   - `email` (string)
   - `schoolCode` (string) - **CRITICAL for data isolation**
   - `createdAt` (timestamp)

### Firestore Indexes:

You may need to create a composite index for the students query:
- Collection: `students`
- Fields: `schoolCode` (Ascending), `name` (Ascending)

Firebase will prompt you to create this index when needed, or you can create it manually in Firebase Console → Firestore → Indexes.

## 🚀 Features Implemented

### ✅ Teacher Login
- Fixed credentials per school (no signup allowed)
- Strict validation to prevent cross-school access
- Firebase Auth integration

### ✅ Student Registration
- Teachers can register students for their own school only
- Creates Firebase Auth account + Firestore document
- Includes name, email, password, class, roll number

### ✅ Student Login
- Students can only login to their registered school
- Cross-school login prevention
- Firebase Auth with school validation

### ✅ Dashboard
- **Teacher Dashboard:**
  - Register new students
  - View list of all students in their school
  - Student details view
  - Logout functionality

- **Student Dashboard:**
  - View own profile information
  - School information
  - Logout functionality

### ✅ Data Isolation
- All queries scoped by `schoolCode`
- Firebase Auth isolated per school project
- Firestore queries filtered by school
- Cross-school access prevention at multiple levels

## 📁 Project Structure

```
lib/
├── constants/
│   └── app_constants.dart          # App-wide constants, teacher credentials
├── services/
│   ├── auth_service.dart           # Firebase Auth service with school isolation
│   └── firebase_initialization_service.dart  # Multi-project Firebase init
├── dashboard_page.dart              # Teacher/Student dashboard
├── login_page.dart                  # Login page for teachers/students
├── role_selection_page.dart         # Role selection (Teacher/Student)
├── school_selection_page.dart       # School selection (A/B/C)
├── student_registration_page.dart   # Student registration (teachers only)
├── firestore_service.dart           # Firestore access service
├── firebase_options.dart            # Firebase configs for each school
└── main.dart                        # App entry point
```

## 🔧 Key Implementation Details

### Authentication Flow:
1. User selects school → Firebase initialized for that school
2. User selects role (Teacher/Student)
3. User enters credentials
4. AuthService validates and authenticates using school-specific Firebase Auth
5. School access verified in Firestore
6. User redirected to dashboard

### Data Isolation Strategy:
1. **Firebase Project Level**: Each school has separate Firebase project
2. **Firebase Auth Level**: Auth instances scoped per school
3. **Firestore Level**: All queries filtered by `schoolCode`
4. **Application Level**: Validation at every step

### Security Features:
- Teacher email/password validation against fixed credentials
- Student school membership verification
- Cross-school access prevention
- School code stored in every document for validation

## 🐛 Troubleshooting

### Teacher Login Fails:
- Ensure teacher account exists in Firebase Console for that school
- Verify email and password match the fixed credentials
- Check Firebase project configuration

### Student Registration Fails:
- Ensure teacher is logged in
- Check email format and password strength (min 6 chars)
- Verify Firebase Auth is enabled in Firebase Console

### Students List Not Showing:
- Check Firestore indexes are created
- Verify `schoolCode` field exists in student documents
- Check Firestore security rules allow read access

### Cross-School Access:
- Verify `schoolCode` is correctly stored in documents
- Check AuthService validation logic
- Ensure Firebase projects are properly isolated

## 📝 Notes

- All teacher accounts must be pre-created in Firebase Console
- Student accounts are created automatically during registration
- The app uses Firebase Email/Password authentication
- All data is isolated per school at multiple levels for security





