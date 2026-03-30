# Step-by-Step: Deploy Firestore Rules to Each School

## 📋 Overview

You have **3 Firebase projects** (one for each school: A, B, C). You need to deploy the same `firestore.rules` file to **each project separately**.

---

## 🎯 Step-by-Step Instructions

### **STEP 1: Open Firebase Console**

1. Go to: **https://console.firebase.google.com/**
2. Make sure you're logged in with your Google account

---

### **STEP 2: Deploy Rules to School A's Firebase Project**

#### 2.1 Select School A's Project
- In the Firebase Console, you'll see a list of your projects
- **Click on School A's Firebase project** (the project ID might be something like `school-a-project` or similar)
- If you're not sure which project is which, check your `firebase_options.dart` file for project IDs

#### 2.2 Navigate to Firestore Rules
- In the left sidebar, look for **"Firestore Database"** (it has a database icon 📊)
- **Click on "Firestore Database"**
- You'll see tabs at the top: **"Data"**, **"Indexes"**, **"Rules"**
- **Click on the "Rules" tab**

#### 2.3 Paste the Rules
- You'll see a code editor with existing rules (probably default rules that deny everything)
- **Delete all existing rules** in the editor
- **Open the `firestore.rules` file** from your project folder
- **Copy ALL the contents** (Ctrl+A, then Ctrl+C)
- **Paste into the Firebase Console editor** (Ctrl+V)

#### 2.4 Publish the Rules
- **Click the "Publish" button** (usually blue/orange button at the top right)
- Wait for confirmation: "Rules published successfully" or similar message
- ✅ **School A rules are now deployed!**

---

### **STEP 3: Deploy Rules to School B's Firebase Project**

#### 3.1 Switch to School B's Project
- At the top of Firebase Console, you'll see the current project name
- **Click on the project name** (it's a dropdown)
- **Select School B's Firebase project** from the list

#### 3.2 Navigate to Firestore Rules
- In the left sidebar, click **"Firestore Database"**
- Click on the **"Rules" tab**

#### 3.3 Paste the Rules
- **Delete all existing rules** in the editor
- **Copy the same `firestore.rules` contents** again
- **Paste into the editor**

#### 3.4 Publish the Rules
- **Click "Publish"**
- Wait for confirmation
- ✅ **School B rules are now deployed!**

---

### **STEP 4: Deploy Rules to School C's Firebase Project**

#### 4.1 Switch to School C's Project
- **Click on the project name** dropdown at the top
- **Select School C's Firebase project**

#### 4.2 Navigate to Firestore Rules
- Click **"Firestore Database"** in left sidebar
- Click on the **"Rules" tab**

#### 4.3 Paste the Rules
- **Delete all existing rules**
- **Copy the same `firestore.rules` contents**
- **Paste into the editor**

#### 4.4 Publish the Rules
- **Click "Publish"**
- Wait for confirmation
- ✅ **School C rules are now deployed!**

---

## 📍 Exact Navigation Path

For each school, follow this exact path:

```
Firebase Console Home
  └─> Select Project (dropdown at top)
      └─> Left Sidebar: "Firestore Database" (📊 icon)
          └─> Top Tabs: "Rules" tab
              └─> Code Editor (paste rules here)
                  └─> "Publish" button (top right)
```

---

## 🔍 How to Identify Your Firebase Projects

If you're not sure which project is which, check your `lib/firebase_options.dart` file:

1. Open `lib/firebase_options.dart` in your project
2. Look for project IDs like:
   ```dart
   // School A
   projectId: 'school-a-project-id'
   
   // School B  
   projectId: 'school-b-project-id'
   
   // School C
   projectId: 'school-c-project-id'
   ```
3. Match these project IDs with the projects in Firebase Console

---

## ✅ Verification Checklist

After deploying to all 3 projects, verify:

- [ ] School A: Rules published successfully
- [ ] School B: Rules published successfully  
- [ ] School C: Rules published successfully
- [ ] All projects show the same rules content
- [ ] No error messages in Firebase Console

---

## 🧪 Test After Deployment

1. **Restart your Flutter app**
2. **Logout and login again** (to refresh authentication)
3. **Try to access attendance screen**
4. **The permission error should be gone!**

---

## ⚠️ Important Notes

1. **Same Rules for All Schools**: You paste the **exact same rules** to all 3 projects
2. **Deploy Separately**: Each school's Firebase project needs its own deployment
3. **Rules Take Effect Immediately**: No need to restart Firebase, just restart your app
4. **If You See Errors**: Check the rules editor for red error indicators

---

## 🆘 Troubleshooting

### "Publish button is grayed out"
- Make sure you've pasted valid rules
- Check for syntax errors (red indicators in editor)

### "Rules not working after deployment"
- Wait 1-2 minutes for rules to propagate
- Restart your Flutter app
- Logout and login again

### "Can't find Firestore Database"
- Make sure Firestore is enabled in your Firebase project
- Go to Firestore Database → Create Database (if not created)

### "Not sure which project is which"
- Check `lib/firebase_options.dart` for project IDs
- Or check your `firebase.json` file

---

## 📝 Quick Reference

**File to Copy From:** `firestore.rules` (in your project root)

**Where to Paste:** Firebase Console → [Select Project] → Firestore Database → Rules tab

**Repeat For:** 
1. School A's project
2. School B's project  
3. School C's project

**Total Time:** ~5 minutes for all 3 projects

---

## 🎉 You're Done!

Once you've deployed rules to all 3 Firebase projects, your permission errors will be fixed and the attendance screen will work properly!
