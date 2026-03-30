# Firestore Security Rules Setup Guide

## 🔐 Overview

This guide explains how to deploy Firestore security rules to fix the `permission-denied` error you're experiencing.

## ⚠️ Important

The `firestore.rules` file has been created in your project root. You need to deploy these rules to each of your Firebase projects (one for each school).

## 📋 Prerequisites

1. Firebase CLI installed: `npm install -g firebase-tools`
2. Logged into Firebase: `firebase login`
3. Access to all your Firebase projects

## 🚀 Deployment Steps

### Option 1: Deploy via Firebase Console (Recommended for Beginners)

1. **For each school's Firebase project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Select the school's Firebase project (e.g., School A's project)
   - Navigate to **Firestore Database** → **Rules** tab
   - Copy the contents of `firestore.rules` file
   - Paste into the rules editor
   - Click **Publish**

2. **Repeat for all schools:**
   - School A's Firebase project
   - School B's Firebase project  
   - School C's Firebase project

### Option 2: Deploy via Firebase CLI (Recommended for Developers)

1. **Initialize Firebase in your project (if not already done):**
   ```bash
   firebase init firestore
   ```
   - Select "Use an existing project"
   - Choose your first school's project
   - Use the default `firestore.rules` file path

2. **Deploy rules to each school's project:**

   **For School A:**
   ```bash
   firebase use <school-a-project-id>
   firebase deploy --only firestore:rules
   ```

   **For School B:**
   ```bash
   firebase use <school-b-project-id>
   firebase deploy --only firestore:rules
   ```

   **For School C:**
   ```bash
   firebase use <school-c-project-id>
   firebase deploy --only firestore:rules
   ```

## 🔍 What These Rules Do

### Security Features:

1. **Authentication Required**: All operations require user authentication
2. **School Isolation**: Handled at application level using `schoolCode` filtering
3. **Data Protection**: 
   - `schoolCode` field cannot be modified after creation
   - Attendance records cannot be updated (as per your requirement - never overwrite old records)
   - Required fields must be present when creating documents
4. **Access Control**:
   - **Teachers**: Can read/write students, attendance records, and announcements
   - **Students**: Can read their own data and school announcements
   - All users must be authenticated to access any data

### Collections Protected:

- ✅ `students` - Student records
- ✅ `teachers` - Teacher records
- ✅ `attendance_records` - Individual attendance records
- ✅ `attendance_sessions` - Class attendance summaries
- ✅ `announcements` - School announcements

## 🧪 Testing the Rules

After deploying, test by:

1. **Login as a teacher** and try to:
   - View students list ✅
   - Mark attendance ✅
   - View attendance records ✅

2. **Login as a student** and try to:
   - View own profile ✅
   - View announcements ✅

## ⚠️ Troubleshooting

### Still Getting Permission Denied?

1. **Check Firebase Console**:
   - Ensure rules are published (not just saved)
   - Check if there are any syntax errors in the rules

2. **Verify User Authentication**:
   - Ensure user is logged in
   - Check if user document exists in `teachers` or `students` collection

3. **Check schoolCode Field**:
   - Ensure all documents have `schoolCode` field
   - Verify `schoolCode` matches user's school

4. **Clear App Cache**:
   - Restart the app
   - Logout and login again

### Rules Not Deploying?

1. **Check Firebase CLI**:
   ```bash
   firebase --version
   firebase login
   ```

2. **Verify Project Access**:
   ```bash
   firebase projects:list
   ```

3. **Check Rules File**:
   - Ensure `firestore.rules` is in project root
   - Verify syntax is correct (no errors in Firebase Console)

## 📝 Notes

- Rules are deployed per Firebase project
- Each school needs its own rules deployment
- Rules take effect immediately after publishing
- Test rules in Firebase Console's Rules Playground before deploying

## 🔗 Resources

- [Firestore Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)
- [Firebase CLI Documentation](https://firebase.google.com/docs/cli)
