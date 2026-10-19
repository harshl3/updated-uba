# SECURITY AND DATA ISOLATION — UBA School Management App (Vidya Sathi)

> **Type**: Evidence-based security analysis from full source-code inspection.
> **Date**: 2026-10-19 | **Scope**: All files under `lib/`, `firestore.rules`, `firebase_options.dart`
> **Note**: Deployed Firebase rules were NOT accessible. Items marked `[DEPLOYED: UNVERIFIED]`
> require manual confirmation in the Firebase Console.

---

## TABLE OF CONTENTS

1. [Architecture Overview](#1-architecture-overview-security-view)
2. [School / Tenant Isolation](#2-school--tenant-isolation)
3. [Authentication & Session Management](#3-authentication--session-management)
4. [Role-Based Access Control](#4-role-based-access-control-rbac)
5. [Firestore Security Rules Analysis](#5-firestore-security-rules-analysis)
6. [User Data — What Is Collected & How Stored](#6-user-data--what-is-collected--how-stored)
7. [Sensitive Secrets & Credentials in Source Code](#7-sensitive-secrets--credentials-in-source-code)
8. [Critical Bug — Student Registration Replaces Teacher Session](#8-critical-bug--student-registration-replaces-teacher-session)
9. [Attendance & Academic Record Integrity](#9-attendance--academic-record-integrity)
10. [File Exports, Excel Reports & Sharing](#10-file-exports-excel-reports--sharing)
11. [Logout & Session Cleanup](#11-logout--session-cleanup)
12. [Input Validation & Injection Prevention](#12-input-validation--injection-prevention)
13. [Network & Transport Security](#13-network--transport-security)
14. [Dependency & Supply Chain Risk](#14-dependency--supply-chain-risk)
15. [Privacy Compliance Gaps](#15-privacy-compliance-gaps)
16. [Prioritized Vulnerability Table](#16-prioritized-vulnerability-table)
17. [Recommended Fixes (Code-Level)](#17-recommended-fixes-code-level)
18. [Security Verification Checklist](#18-security-verification-checklist)

---

## 1. Architecture Overview (Security View)

```
User Device (Android / iOS)
        │
        ▼
┌─────────────────────────────────────────────────────────┐
│  Flutter App  (lib/)                                    │
│                                                         │
│  school_selection_page.dart                             │
│      │  triggers FirebaseInitializationService          │
│      ▼                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐              │
│  │ schoolA  │  │ schoolB  │  │ schoolC  │  FirebaseApp  │
│  │ Firebase │  │ Firebase │  │ Firebase │  per school   │
│  └──────────┘  └──────────┘  └──────────┘              │
│       │               │              │                  │
│   Firebase Auth    Firebase Auth  Firebase Auth         │
│   Cloud Firestore  Cloud Firestore Cloud Firestore      │
│   (SEPARATE PROJECTS — physical isolation)              │
│                                                         │
│  AuthService ─────────► per-school Firebase Auth        │
│  FirestoreService ─────► per-school Firestore instance  │
│                                                         │
│  Teacher flows (UI-gated only, no server role check)    │
│  Student flows (UI-gated only, no server role check)    │
└─────────────────────────────────────────────────────────┘
```

**Primary isolation model**: Three separate Firebase projects (one per school). Each has its own
Authentication namespace and Firestore database. Cross-school data access is physically impossible
at the SDK level — they are different databases.

---

## 2. School / Tenant Isolation

### 2.1 Isolation Mechanisms (Verified — Source Code)

| Mechanism | File | What It Does |
|-----------|------|-------------|
| Separate Firebase projects | `lib/firebase_options.dart` | Each school has its own `projectId`, `apiKey`, `appId` |
| Per-school Firebase init | `lib/services/firebase_initialization_service.dart` | `initializeForSchool()` creates isolated `FirebaseApp` instances: `schoolA`, `schoolB`, `schoolC` |
| Per-school Firestore | `lib/firestore_service.dart` | `FirebaseFirestore.instanceFor(app: schoolApp)` — all queries target the correct school's DB |
| `schoolCode` in all records | `lib/services/auth_service.dart` | Every Firestore document stores `schoolCode`; all queries filter by it |

### 2.2 What This Isolation Protects Against

- A teacher/student authenticated to School A **cannot query** School B's Firestore — different database
- Cross-school writes are physically blocked at the Firebase project level
- Even if `schoolCode` filtering in app code were removed, wrong Firebase instance returns empty results

### 2.3 Isolation Gaps

| Gap | Severity | Detail |
|-----|----------|--------|
| Firebase API keys exposed in APK | LOW | `firebase_options.dart` contains all 3 schools' API keys. Extractable from APK via jadx/apktool. Firebase keys are semi-public by design; security relies on Firestore rules. |
| All 3 school configs bundled together | LOW | Any installed user sees configs for all schools, not just their own |
| No server-side schoolCode ownership check | MEDIUM | Firestore rules do not verify that `request.auth.uid` belongs to the `schoolCode` being queried |

---

## 3. Authentication & Session Management

### 3.1 Teacher Login Flow (Verified)

**File**: `lib/services/auth_service.dart` → `loginTeacher()`

```
1. Validate schoolCode ∈ [A, B, C]
2. STRICT: email must match hardcoded teacher email for that school
3. STRICT: password must match hardcoded teacher password (client-side check)
4. Firebase Auth → signInWithEmailAndPassword() on school's Firebase instance
5. _verifyTeacherSchoolAccess() → read/create teachers Firestore doc
6. Return UserCredential
```

**Issues**:
- **CRITICAL (V-01)**: Teacher passwords hardcoded in `app_constants.dart` — extractable from APK
- **LOW**: Client-side password comparison (step 3) before Firebase is called — redundant and exposes credential logic to decompilation
- **LOW**: `_verifyTeacherSchoolAccess()` silently swallows non-AuthException errors. If Firestore is unavailable, login still succeeds — school-membership verification is skipped

### 3.2 Student Login Flow (Verified)

**File**: `lib/services/auth_service.dart` → `loginStudent()`

```
1. Validate schoolCode
2. Firebase Auth → signInWithEmailAndPassword() on school's Firebase instance
3. _verifyStudentSchoolAccess() → check student doc in Firestore, verify schoolCode matches
4. Return UserCredential
```

**Issues**:
- **MEDIUM**: No pre-Auth school-membership check (unlike teacher login). Firebase rejects wrong credentials, but any email can be tried against any school's Auth namespace
- **GOOD**: After Auth, school membership IS verified in Firestore — a student from School A cannot log into School B even with the same password, because their Firestore doc won't exist in School B

### 3.3 Student Registration (Critical Session Bug — see Section 8)

### 3.4 Session Token Management

| Aspect | Status | Detail |
|--------|--------|--------|
| Token refresh | ✅ Auto | Firebase Auth SDK auto-refreshes ID tokens every ~1 hour |
| Token expiry | ✅ Enforced | Tokens expire after 1 hour; SDK handles silently |
| Session persistence | ✅ On-device | Firebase Auth persists session in device storage |
| Explicit sign-out | ✅ Implemented | `auth.signOut()` called in `AuthService.logout()` |
| Multi-device concurrent sessions | ❌ Not handled | Firebase allows concurrent logins; no single-device enforcement |
| Re-auth on app resume | ❌ Missing | No re-authentication check when app comes back from background |
| Server-side session invalidation | ❌ Not possible | Firebase tokens valid ~1 hour even after signOut; cannot be instantly revoked |
| Account disable propagation | ✅ Works | Disabled Firebase user cannot obtain new tokens |

---

## 4. Role-Based Access Control (RBAC)

### 4.1 Current State

Role enforcement is **entirely client-side**. There are no Firebase Custom Claims, no Cloud
Functions, and no Firestore rules that distinguish teachers from students.

The only role enforcement mechanisms:
- **UI routing**: Teacher → teacher dashboard; Student → student dashboard
- **Teacher email validation**: Teacher login validates email matches school's fixed teacher email
- **Navigation guard**: `PopScope(canPop: false)` prevents back-navigation out of dashboards

### 4.2 Role Escalation Risk

A student with a modified APK (or using the Firebase SDK directly) can:
1. Authenticate with valid student credentials
2. Call any Firestore write operation that a teacher would
3. Firestore rules allow all writes because `isAuthenticated()` is true regardless of role

### 4.3 Teacher vs Student Permission Matrix

| Action | Intended | App Enforced | Firestore Enforced |
|--------|----------|-------------|-------------------|
| Register new student | Teacher only | ✅ UI routing | ❌ Any auth user |
| Mark attendance | Teacher only | ✅ UI routing | ❌ Any auth user |
| Create announcement | Teacher only | ✅ UI routing | ❌ Any auth user |
| Delete announcement | Teacher only | ✅ UI routing | ❌ Any auth user |
| Post school updates | Teacher only | ✅ UI routing | ❌ Any auth user |
| View student list | Teacher only | ✅ UI routing | ❌ Any auth user |
| View student details | Teacher only | ✅ UI routing | ❌ Any auth user |
| Edit student details | Teacher only | ✅ UI routing | ❌ Any auth user |
| Delete student record | Teacher only | ✅ UI routing | ❌ Any auth user |
| View own profile | Student | ✅ UI routing | ❌ Reads ALL students |
| View announcements | Both | ✅ Both dashboards | ✅ isAuthenticated() |
| View school updates | Both | ✅ Both dashboards | ❌ PUBLIC (no auth) |

---

## 5. Firestore Security Rules Analysis

**File**: `firestore.rules` (LOCAL rules — deployed rules may differ `[DEPLOYED: UNVERIFIED]`)

### 5.1 `students` Collection

```javascript
allow read:   if isAuthenticated();          // ❌ Any auth user reads ALL students' PII
allow create: if isAuthenticated() &&
  hasAll(['name','email','schoolCode']);     // ❌ Any auth user (student) can create
allow update: if isAuthenticated() &&
  !affectedKeys().hasAny(['schoolCode']);   // ❌ Any auth user; schoolCode immutable ✅
allow delete: if isAuthenticated();          // ❌ Any auth user can delete any student
```

**Risk**: Student can read all peers' PII (name, email, DOB, father's name, mobile, address,
academic records). Student can also delete any student's Firestore document.

### 5.2 `teachers` Collection

```javascript
allow read:   if isAuthenticated();          // ❌ Students can read teacher records
allow create: if isAuthenticated() &&
  request.auth.uid == teacherId &&          // ✅ Only own document
  hasAll(['email','schoolCode']);
allow update: if isAuthenticated() &&
  request.auth.uid == teacherId &&          // ✅ Only own document
  !affectedKeys().hasAny(['schoolCode']);   // ✅ schoolCode immutable
allow delete: if false;                      // ✅ Cannot delete — excellent
```

**Risk**: Students can read teacher email and schoolCode from Firestore.

### 5.3 `attendance_records` Collection

```javascript
allow read:   if isAuthenticated();          // ❌ All auth users read all records
allow create: if isAuthenticated() &&
  hasAll(['studentName','className','date','status','schoolCode']); // ❌ Any auth user
allow update: if false;                      // ✅ Immutable after creation — excellent
allow delete: if isAuthenticated();          // ❌ Any auth user can delete records
```

**Risk**: Students can create fake attendance entries or delete existing absence records.

### 5.4 `attendance_sessions` Collection

```javascript
allow read:   if isAuthenticated();          // ❌ All auth users
allow create: if isAuthenticated() &&
  hasAll(['className','date','totalStudents','presentCount','absentCount','schoolCode']);
allow update: if isAuthenticated() &&        // ❌ Any auth user
  !affectedKeys().hasAny(['schoolCode']);
allow delete: if isAuthenticated();          // ❌ Any auth user
```

**Risk**: Students can tamper with summary attendance counts.

### 5.5 `announcements` Collection

```javascript
allow read:   if isAuthenticated();          // ✅ Reasonable
allow create: if isAuthenticated() &&
  hasAll(['schoolCode']);                    // ❌ Any auth user can post announcements
allow update: if isAuthenticated();          // ❌ Any auth user can edit
allow delete: if isAuthenticated();          // ❌ Any auth user can delete
```

### 5.6 `svpcet_updates` Collection

```javascript
allow read: if true;                         // ❌❌ PUBLIC — no authentication required
allow create: if isAuthenticated() &&
  hasAll(['title','message','schoolCode']); // ❌ Any auth user
allow update: if isAuthenticated();
allow delete: if isAuthenticated();
```

**Risk**: School updates are readable by anyone on the internet without any Firebase account.
This is likely unintentional.

### 5.7 What Is Missing from All Rules

- No `request.auth.token.role == 'teacher'` check (needs Custom Claims)
- No verification that `request.auth.uid` belongs to any teacher document
- No field-value validation (e.g., `status` must be `"Present"` or `"Absent"`)
- No string length limits on `title` / `message` / `name` fields
- No numeric range validation (`presentCount >= 0`)

---

## 6. User Data — What Is Collected & How Stored

### 6.1 Personal Data Inventory

| Field | Who It Belongs To | Stored In | Readable By (per rules) |
|-------|------------------|-----------|-------------------------|
| `name` | Student | Firestore `students` | Any authenticated user |
| `email` | Student | Firestore `students` + Firebase Auth | Any authenticated user |
| `className` | Student | Firestore `students` | Any authenticated user |
| `rollNumber` | Student | Firestore `students` | Any authenticated user |
| `fathersName` | Student | Firestore `students` | Any authenticated user |
| `gender` | Student | Firestore `students` | Any authenticated user |
| `dob` | Student | Firestore `students` | Any authenticated user |
| `mobileNumber` | Student | Firestore `students` | Any authenticated user |
| `address` | Student | Firestore `students` | Any authenticated user |
| `dateOfAdmission` | Student | Firestore `students` | Any authenticated user |
| `previousPercentage` | Student | Firestore `students` | Any authenticated user |
| `parentsMobileNumber` | Student | Firestore `students` | Any authenticated user |
| `currentPercentage` | Student | Firestore `students` | Any authenticated user |
| `email` (teacher) | Teacher | Firestore `teachers` | Any authenticated user |
| Teacher passwords | Teacher | **APK source code** | Anyone with the APK |

### 6.2 What Is NOT Stored (Positive Findings)

- ✅ Passwords are NOT stored in Firestore — only in Firebase Auth
- ✅ No local SQLite or SharedPreferences storage of student PII found
- ✅ No custom logging of user data found in source code
- ✅ Attendance record `status` only contains `"Present"` or `"Absent"` — no biometric data

### 6.3 Data Retention

- No deletion policy in code — records persist indefinitely in Firestore
- `attendance_records`: `allow update: if false` — permanently immutable once written
- No student account self-deletion feature
- No data export or erasure mechanism (GDPR / DPDP compliance gap)

### 6.4 Data Minimization Issues

- Optional fields (address, DOB, father's name, parent mobile) default to empty string `''`
  rather than being omitted — empty strings are stored even when not provided
- `currentPercentage` stored as `''` at registration — no code path found to update it

---

## 7. Sensitive Secrets & Credentials in Source Code

### 7.1 Hardcoded Teacher Passwords — **HIGH SEVERITY**

**File**: `lib/constants/app_constants.dart`, `getTeacherPassword()` method

```dart
case schoolCodeA: return 'schoola123';
case schoolCodeB: return 'schoolb123';
case schoolCodeC: return 'schoolc123';
```

**Impact**: Anyone who installs the APK and decompiles it using free tools (jadx, apktool, dex2jar)
can extract these passwords. Combined with the hardcoded teacher emails, this gives full teacher
access to any school — including ability to read all student PII, register fake students, and
mark fraudulent attendance.

**Git risk**: If this file is committed to a public GitHub repository, the passwords are exposed
to the entire internet. Verify repository visibility immediately.

### 7.2 Firebase API Keys in Source — **LOW SEVERITY**

**File**: `lib/firebase_options.dart`

All three schools' API keys, App IDs, Project IDs, Sender IDs are bundled in the APK.

Firebase API keys for mobile/web are designed to be public — they identify the app but do not
grant access. Security relies entirely on Firestore security rules and Firebase Auth.
However, exposing all 3 configs means a curious user could interact directly with any school's
Firebase project via the REST API, subject only to security rules.

### 7.3 Risk Summary

| Secret | Location | Who Can Access | Severity |
|--------|----------|---------------|----------|
| School A teacher password (`schoola123`) | APK / source | Anyone with APK | HIGH |
| School B teacher password (`schoolb123`) | APK / source | Anyone with APK | HIGH |
| School C teacher password (`schoolc123`) | APK / source | Anyone with APK | HIGH |
| Firebase API keys (all 3 schools) | APK / source | Anyone with APK | LOW |
| Firebase App IDs (all 3 schools) | APK / source | Anyone with APK | LOW |

---

## 8. Critical Bug — Student Registration Replaces Teacher Session

**File**: `lib/services/auth_service.dart`, `registerStudent()`, line ~221

### 8.1 Root Cause

```dart
final userCredential = await auth.createUserWithEmailAndPassword(
  email: email.toLowerCase().trim(),
  password: password,
);
```

Firebase's `createUserWithEmailAndPassword()` does two things simultaneously:
1. Creates the new Firebase Auth account
2. **Automatically signs in as the new user**, replacing whoever was signed in

### 8.2 What Happens Step by Step

```
Before registration:  auth.currentUser = TEACHER_UID (teacher is logged in)

Teacher calls registerStudent() →
  auth.createUserWithEmailAndPassword() →
    Firebase creates student account AND signs in as student

After registration:   auth.currentUser = NEW_STUDENT_UID  ← Teacher session GONE

Teacher dashboard still shows on screen.
All subsequent Firestore writes carry NEW_STUDENT_UID, not TEACHER_UID.
```

### 8.3 Current Impact

With existing permissive Firestore rules (only `isAuthenticated()` check), operations still
succeed because the student is also authenticated. However:
- Audit trails (if ever added) would show student UID performing teacher actions
- If Firestore rules are ever tightened to require teacher role, ALL teacher operations
  immediately after registration will silently fail

### 8.4 Fix — Use a Secondary Firebase App Instance

```dart
// In registerStudent():
final tempAppName = 'reg_${DateTime.now().millisecondsSinceEpoch}';
final tempApp = await Firebase.initializeApp(
  name: tempAppName,
  options: _getFirebaseOptions(schoolCode),
);
try {
  final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
  final userCredential = await tempAuth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  // Write Firestore doc using teacher's main Firestore instance
  // ...
  return userCredential;
} finally {
  await tempApp.delete(); // Always clean up temp app
}
```

**Alternative (recommended for production)**: Use Firebase Admin SDK via a Cloud Function.
The teacher calls the function; the function creates the student account server-side.
Teacher session is never affected.

---

## 9. Attendance & Academic Record Integrity

### 9.1 Positive Protections (Verified)

| Protection | Status | Detail |
|-----------|--------|--------|
| Attendance records immutable | ✅ | `allow update: if false` in Firestore rules |
| Duplicate prevention | ✅ | App checks `attendance_sessions` doc existence before submission |
| Batch writes used | ✅ | All attendance records written atomically |
| `schoolCode` in all records | ✅ | Defense-in-depth |
| Date stored as Firestore Timestamp | ✅ | Not a string — prevents format inconsistencies |

### 9.2 Integrity Weaknesses

| Issue | Risk Level | Detail |
|-------|-----------|--------|
| Any auth user can CREATE attendance records | MEDIUM | Student could fabricate their own attendance |
| Any auth user can DELETE attendance records | MEDIUM | Student could delete their absence records |
| Session summary counts are client-computed | LOW | `presentCount`/`absentCount` stored from client — no server validation |
| Document ID uses student name string | LOW | `"StudentName_Class 5_2026-01-22"` — name changes break convention; special chars risk |
| Duplicate check uses session doc — bypassable | LOW | Future code changes skipping session creation could allow duplicates |

### 9.3 Non-Security Quality Issue

In `lib/teacher/attendance_screen.dart`, the "Total" stat uses `_attendanceMap.length` (a
string map) instead of `_studentList.length`. These can briefly diverge during load. Not a
security issue but a data accuracy issue.

---

## 10. File Exports, Excel Reports & Sharing

**Files**: `lib/teacher/attendance_report_screen.dart`, `attendance_report_service.dart`

### 10.1 Report Generation Flow

```
Teacher selects class + date range
    → Firestore query: attendance_records filtered by className + schoolCode
    → excel package generates .xlsx
    → File saved to getApplicationDocumentsDirectory()
    → share_plus opens Android/iOS Sharesheet
```

### 10.2 Security Concerns

| Concern | Severity | Detail |
|---------|----------|--------|
| Files contain student PII | HIGH (data) | Excel files include names, roll numbers, attendance status — personal data |
| Files persist after logout | MEDIUM | `path_provider` saves to app documents directory; not deleted on logout |
| No cleanup on logout | MEDIUM | `AuthService.logout()` only calls `auth.signOut()` — no file cleanup |
| Files outside app control after share | LOW | Once shared via Sharesheet (WhatsApp, email, etc.), files are uncontrolled |
| No watermark or DLP controls | LOW | Exported files have no ownership or confidentiality markings |
| Deprecated `Share.shareXFiles` API | INFO | `attendance_report_screen.dart:442` — migrate to `SharePlus.instance.share()` |

---

## 11. Logout & Session Cleanup

**Files**: `lib/services/auth_service.dart` → `logout()`, teacher/student dashboard logout handlers

### 11.1 What Logout Does (Verified)

```dart
// AuthService.logout():
final auth = _getAuthSync(schoolCode);
await auth.signOut();

// Dashboard handler:
await AuthService.logout(widget.schoolCode);
Navigator.pushAndRemoveUntil(context,
  MaterialPageRoute(builder: (_) => const SchoolSelectionPage()),
  (route) => false,  // clears entire navigation stack
);
```

### 11.2 Logout Gaps

| Gap | Severity | Detail |
|-----|----------|--------|
| Exported report files not deleted | MEDIUM | PII remains in app storage after logout |
| Pending Firestore listeners not cancelled | LOW | StreamBuilders may deliver one final snapshot after logout |
| `FirebaseInitializationService._initializedApps` not cleared | INFO | Firebase App instances remain in memory for process lifetime |
| Server-side token not instantly invalidated | INFO | Firebase ID tokens valid ~1 hour; cannot be revoked server-side immediately |
| No re-auth on app resume | LOW | If app backgrounded and resumed, no re-authentication check |

---

## 12. Input Validation & Injection Prevention

### 12.1 Client-Side Validation (Verified — Good)

| Field | Validation |
|-------|-----------|
| Email | RegExp: `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$` |
| Password | Minimum 6 characters |
| Required fields | FormKey validation before submission |
| Student name | `.trim()` applied; empty check |
| Date fields | Read-only with DatePicker — cannot be typed |
| Roll number | Required, trimmed |

### 12.2 Server-Side Validation (Firestore Rules — Weak)

Firestore rules only check field **existence** (`hasAll()`). They do NOT validate:
- String lengths (title/message could be arbitrarily long)
- Enum values (`status` must be `"Present"` or `"Absent"`)
- Email format
- Numeric ranges (`presentCount >= 0`, `totalStudents > 0`)
- Timestamp type

### 12.3 Injection Risk Assessment

- **SQL injection**: ❌ Not applicable — Firestore uses typed SDK, not SQL
- **XSS**: ❌ Not applicable — Flutter is compiled native code, not a browser
- **Document ID injection**: LOW risk — Firestore rejects invalid doc IDs; but names with
  path-separator chars (`/`) in edge cases could cause unexpected behavior
- **Firestore query injection**: ❌ Not applicable — queries use SDK methods, not query strings

---

## 13. Network & Transport Security

| Aspect | Status | Detail |
|--------|--------|--------|
| Firebase SDK uses TLS 1.2+ | ✅ | Enforced by Firebase SDK on all connections |
| Certificate pinning | ❌ Not implemented | Man-in-the-middle possible on rooted devices / custom CAs |
| Firestore offline persistence | ✅ Default on | Firebase SDK caches data locally for offline use |
| Local cache encryption | ❌ Not encrypted | Firestore local cache (SQLite) is NOT encrypted by default |
| Traffic interception risk | MEDIUM | Possible on rooted Android devices with custom certificate authorities |

---

## 14. Dependency & Supply Chain Risk

From `pubspec.yaml`:

| Package | Version | Risk Level | Note |
|---------|---------|-----------|------|
| `firebase_auth` | ^5.5.4 | LOW | Google-maintained |
| `cloud_firestore` | ^5.6.5 | LOW | Google-maintained |
| `firebase_core` | ^3.13.0 | LOW | Google-maintained |
| `url_launcher` | ^6.3.1 | LOW | Flutter-team maintained; deprecated API in use |
| `excel` | ^4.0.6 | MEDIUM | Community package — review changelog periodically |
| `share_plus` | ^10.1.4 | LOW | FlutterCommunity; deprecated API in use |
| `path_provider` | ^2.1.5 | LOW | Flutter-team maintained |
| `flutter_pdfview` | ^1.3.2 | MEDIUM | Community WebView-based; verify no known CVEs |

**Deprecated APIs in use** (confirmed by `flutter analyze`):
- `canLaunch` / `launch` in `contact_us_screen.dart` → migrate to `canLaunchUrl` / `launchUrl`
- `Share.shareXFiles` in `attendance_report_screen.dart` → migrate to `SharePlus.instance.share()`
- `withOpacity()` throughout → migrate to `.withValues(alpha:)`
- `dataRowHeight` in `excel_preview_screen.dart` → migrate to `dataRowMinHeight`/`dataRowMaxHeight`

---

## 15. Privacy Compliance Gaps

| Requirement | Status | Detail |
|-------------|--------|--------|
| Privacy policy | ⚠️ Partial | Links to Google Sites page; content not verified in this review |
| Data minimization | ⚠️ Partial | Optional fields stored as `''` rather than omitted |
| Right to access own data | ❌ Missing | No self-service data export for students |
| Right to erasure | ❌ Missing | No account or data deletion flow |
| Data retention policy | ❌ Missing | Records persist indefinitely |
| Consent for sensitive data | ❌ Missing | No in-app consent flow for DOB, family details, mobile numbers |
| Children's data (DPDP Act 2023) | ⚠️ HIGH RISK | App collects data on school students who may be minors. India's Digital Personal Data Protection Act 2023 requires verifiable parental consent for processing data of minors (under 18). No age verification or parental consent mechanism exists. |
| Breach notification plan | ❌ Missing | No process documented (not a code issue, but a gap) |

---

## 16. Prioritized Vulnerability Table

| ID | Title | Severity | File | Action |
|----|-------|----------|------|--------|
| V-01 | Hardcoded teacher passwords extractable from APK | 🔴 HIGH | `lib/constants/app_constants.dart:57-65` | Remove passwords; use Firebase Auth directly |
| V-02 | Student registration replaces teacher session | 🔴 HIGH | `lib/services/auth_service.dart:221` | Use secondary FirebaseApp or Cloud Function |
| V-03 | No server-side role enforcement in Firestore rules | 🔴 HIGH | `firestore.rules` — all collections | Add Custom Claims or Firestore role check |
| V-04 | Students can read all other students' PII | 🟠 MEDIUM | `firestore.rules:students read` | Restrict to teacher role or own UID |
| V-05 | `svpcet_updates` publicly readable (no auth) | 🟠 MEDIUM | `firestore.rules:119` | Change to `isAuthenticated()` |
| V-06 | Any auth user can delete student Firestore records | 🟠 MEDIUM | `firestore.rules:students delete` | Restrict to teacher role |
| V-07 | Any auth user can delete attendance records | 🟠 MEDIUM | `firestore.rules:attendance_records delete` | Restrict to teacher role |
| V-08 | Report files (student PII) not cleaned up on logout | 🟡 LOW | `lib/services/auth_service.dart:logout()` | Delete `.xlsx` files on logout |
| V-09 | All 3 Firebase configs bundled in single APK | 🟡 LOW | `lib/firebase_options.dart` | Awareness only; enforce via strict Firestore rules |
| V-10 | Deprecated `url_launcher` API in Contact Us | 🟢 INFO | `lib/common/contact_us_screen.dart` | Migrate to `canLaunchUrl` / `launchUrl` |
| V-11 | Deprecated `Share.shareXFiles` in report screen | 🟢 INFO | `lib/teacher/attendance_report_screen.dart:442` | Migrate to `SharePlus.instance.share()` |
| V-12 | No data retention or deletion policy | 🟡 LOW | All Firestore collections | Add TTL or deletion workflow |
| V-13 | Teacher Firestore doc readable by any auth user | 🟡 LOW | `firestore.rules:teachers read` | Restrict to teacher UID only |
| V-14 | Minors' PII collected without consent mechanism | 🟠 MEDIUM | Registration flow | Add parental consent step (DPDP Act 2023) |
| V-15 | Client-computed attendance counts stored as facts | 🟡 LOW | `attendance_sessions` Firestore docs | Add server-side count validation |

---

## 17. Recommended Fixes (Code-Level)

### Fix V-01 — Remove Hardcoded Passwords

```dart
// lib/constants/app_constants.dart
// REMOVE this entire method:
static String getTeacherPassword(String schoolCode) { ... }

// lib/services/auth_service.dart — loginTeacher()
// REMOVE these lines:
final expectedPassword = AppConstants.getTeacherPassword(schoolCode);
if (password != expectedPassword) {
  throw AuthException('Invalid password for teacher account.');
}
// Let Firebase Auth validate the password — it returns wrong-password error
```

Teacher accounts should be provisioned via the Firebase Console and have strong, unique passwords
that are NOT in source code.

### Fix V-02 — Fix Student Registration Session Bug

```dart
// lib/services/auth_service.dart — registerStudent()
final tempAppName = 'reg_${DateTime.now().millisecondsSinceEpoch}';
FirebaseApp? tempApp;
try {
  tempApp = await Firebase.initializeApp(
    name: tempAppName,
    options: _getFirebaseOptions(schoolCode), // use school's options
  );
  final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
  final userCredential = await tempAuth.createUserWithEmailAndPassword(
    email: email.toLowerCase().trim(),
    password: password,
  );
  // Write student Firestore doc using existing teacher's Firestore instance
  final firestore = await FirestoreService.firestore(schoolCode);
  await firestore.collection('students')
      .doc(userCredential.user!.uid).set({ ... });
  return userCredential;
} finally {
  await tempApp?.delete(); // Always clean up
}
```

### Fix V-03 — Add Role Enforcement to Firestore Rules

**Option A — Firestore-based role lookup (no Firebase Admin needed)**:
```javascript
function isTeacher() {
  return exists(/databases/$(database)/documents/teachers/$(request.auth.uid));
}
function isStudent() {
  return isAuthenticated() && !isTeacher();
}

match /students/{studentId} {
  allow read: if isTeacher() || request.auth.uid == studentId;
  allow create: if isTeacher();
  allow update: if isTeacher() &&
    !request.resource.data.diff(resource.data).affectedKeys().hasAny(['schoolCode']);
  allow delete: if isTeacher();
}

match /attendance_records/{recordId} {
  allow read: if isAuthenticated();
  allow create: if isTeacher();
  allow update: if false;
  allow delete: if isTeacher();
}
```

**Option B — Firebase Custom Claims (more scalable)**:
Set `role: 'teacher'` claim when teacher logs in via Cloud Function, then check:
```javascript
function isTeacher() { return request.auth.token.role == 'teacher'; }
```

### Fix V-05 — Require Auth for School Updates

```javascript
// firestore.rules — svpcet_updates
// Change from:
allow read: if true;
// To:
allow read: if isAuthenticated();
```

### Fix V-08 — Clean Up Report Files on Logout

```dart
// lib/services/auth_service.dart
import 'package:path_provider/path_provider.dart';
import 'dart:io';

static Future<void> logout(String schoolCode) async {
  try {
    // Delete exported report files
    final dir = await getApplicationDocumentsDirectory();
    final files = dir.listSync().whereType<File>()
        .where((f) => f.path.endsWith('.xlsx') || f.path.endsWith('.pdf'));
    for (final file in files) {
      await file.delete().catchError((_) {}); // Ignore individual failures
    }
  } catch (_) {}
  try {
    final auth = _getAuthSync(schoolCode);
    await auth.signOut();
  } catch (_) {}
}
```

### Fix V-10 — Migrate Deprecated url_launcher API

```dart
// lib/common/contact_us_screen.dart
// Change from (deprecated):
if (await canLaunch(url)) { await launch(url); }

// To:
final uri = Uri.parse(url);
if (await canLaunchUrl(uri)) {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
```

---

## 18. Security Verification Checklist

Run this checklist before every release and after any Firebase rule change.

### Authentication
- ✅ Firebase Auth used for all logins — no custom password hashing
- ✅ Wrong password returns FirebaseAuthException, not a null user
- ✅ Email lowercased and trimmed before Auth calls
- ✅ Passwords NOT stored in Firestore
- ❌ **[V-01]** Teacher passwords hardcoded in source — remove `getTeacherPassword()`
- ❌ **[V-02]** Student registration replaces teacher session — use secondary FirebaseApp
- ❌ No re-authentication check when app resumes from background

### Authorization (Firestore Rules)
- ❌ **[V-03]** Rules do not enforce teacher vs student role
- ❌ **[V-04]** Students can read all other students' PII
- ❌ **[V-05]** `svpcet_updates` readable without authentication
- ❌ **[V-06]** Any auth user can delete student records
- ❌ **[V-07]** Any auth user can delete attendance records
- ❌ **[V-13]** Teacher Firestore docs readable by students

### School / Tenant Isolation
- ✅ Separate Firebase projects per school (physical isolation)
- ✅ `FirestoreService` always uses per-school Firebase instance
- ✅ `schoolCode` stored in all Firestore documents
- ✅ All queries filter by `schoolCode`
- ❌ Firestore rules do not verify user's school membership server-side

### Data & File Handling
- ✅ Passwords not logged or stored in Firestore
- ✅ Attendance records immutable after creation (`allow update: if false`)
- ❌ **[V-08]** Report files not cleaned up on logout
- ❌ **[V-12]** No data retention policy (records persist indefinitely)
- ❌ **[V-14]** No parental consent for minors' data

### Code Quality / Deprecated APIs
- ❌ **[V-10]** `canLaunch`/`launch` → migrate to `canLaunchUrl`/`launchUrl`
- ❌ **[V-11]** `Share.shareXFiles` → migrate to `SharePlus.instance.share()`
- ❌ `withOpacity()` → migrate to `.withValues(alpha:)`
- ❌ `dataRowHeight` → migrate to `dataRowMinHeight`/`dataRowMaxHeight`

### Deployment Verification `[DEPLOYED: UNVERIFIED]`
- [ ] Confirm deployed Firestore rules match `firestore.rules` in this repo
- [ ] Confirm teacher Firebase Auth accounts exist in each school's Firebase project
- [ ] Confirm `svpcet_updates` read rule is NOT `if true` in production
- [ ] Confirm `.gitignore` excludes `google-services.json` and signing keystores
- [ ] Confirm app repository is private (to protect hardcoded passwords)
- [ ] Confirm Firebase project quotas are set to limit abuse

---

## Maintenance Rules

- Update this document whenever Firebase rules change, new features are added, or a fix is implemented
- Mark items with: ✅ Fixed | ❌ Open | ⚠️ Partially mitigated | `[DEPLOYED: UNVERIFIED]`
- **Never include** actual credentials, student records, or production API secrets here
- Re-run `flutter analyze` after every change and address any security-relevant warnings
