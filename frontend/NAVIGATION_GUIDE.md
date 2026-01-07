# 🧭 AIREA Flutter App - Complete Navigation Guide

## 📱 Navigation Flow Overview

This document shows how ALL pages in the AIREA app are connected and how users can navigate between them.

---

## 🏥 PATIENT NAVIGATION

### 1️⃣ Authentication Flow

```
Welcome Page
    ↓
Role Selection (Patient/Doctor)
    ↓
Patient Login
    ├─→ [Login Button] → Patient Home Screen
    └─→ [Create Account Link] → Patient Create Account
                                    ↓
                                Patient More Info (Personal Details)
                                    ↓
                                Patient Contact (Phone & Emergency)
                                    ↓
                                Patient Upload Reports (Medical Files)
                                    ↓
                                Patient Allergies (Medical Conditions)
                                    ↓
                                Patient Account Created ✓
                                    ↓
                                Patient Home Screen
```

**Files:**
- `welcome_page.dart` → `role_selection_page.dart` → `patient_login_page.dart`
- `patient_create_account.dart` → `patient_more_info.dart` → `patient_contact.dart`
- `patient_upload_reports.dart` → `patient_allergies.dart` → `patient_account_created.dart`

---

### 2️⃣ Patient Home Screen (Main Dashboard)

```
Patient Home Screen
    ├─→ [Profile Icon] → Patient Profile
    ├─→ [Notifications Icon] → Patient Notifications
    ├─→ [Cough Card] → Patient Cough Count
    └─→ [Bottom Nav]
            ├─→ Home (current)
            ├─→ Device → Patient Connect Device Option
            └─→ Trends → Patient Summary Page
```

**Bottom Navigation Bar (3 tabs):**
1. **Home** - Shows live vitals (SpO2, Heart Rate, Temperature, Cough Count)
2. **Device** - Connect to wearable device
3. **Trends** - View summaries and analytics

**File:** `patient_homeScreen.dart`

---

### 3️⃣ Device Connection Flow (8 Pages)

```
Patient Connect Device Option
    ├─→ [Yes] → Patient Connect Device Code (Enter pairing code)
    │               ↓
    │           Patient Device Guidance (Setup instructions)
    │               ↓
    │           Patient Device Connected ✓
    │               ↓
    │           Patient Device Dashboard
    │               ├─→ [Disconnect] → Patient Device Disconnect
    │               └─→ [Manual] → Patient Device Manual
    └─→ [No] → Back to Home
```

**Files:**
- `patient_connect_device_option.dart`
- `patient_connect_device_code.dart`
- `patient_device_guidance.dart`
- `patient_device_connected.dart`
- `patient_device_dashboard.dart`
- `patient_device_disconnect.dart`
- `patient_device_manual.dart`

---

### 4️⃣ Doctor Connection Flow (7 Pages)

```
Patient Connect Doctor Option (from Home or Menu)
    ├─→ [Yes] → Patient Connect Doctor ID (Enter doctor ID)
    │               ↓
    │           Patient Doctor Guidance (What to expect)
    │               ↓
    │           Patient Pending Message (Waiting for approval)
    │               ↓
    │           Patient Connected with Doctor ✓
    │               ↓
    │           Patient Contact Doctor (Chat/Call)
    │               ↓
    │           Patient Doctor Details (View doctor info)
    └─→ [No] → Back to previous screen
```

**Files:**
- `patient_connect_doctor_option.dart`
- `patient_connect_doctor_id.dart`
- `patient_doctor_guidance.dart`
- `patient_pending_message.dart`
- `patient_connected_with_doctor.dart`
- `patient_contact_doctor.dart`
- `patient_doctor_details.dart`

---

### 5️⃣ Cough Monitoring & Analytics

```
Patient Cough Count (Real-time Analysis)
    ├─→ Shows waveform visualization
    ├─→ Cough frequency per hour
    ├─→ Dry/Wet cough breakdown
    └─→ [Bottom Nav] → Navigate to Home/Device/Trends
```

**File:** `patient_cough_count.dart`

---

### 6️⃣ Summary & Trends Pages

```
Patient Summary Page (Calendar view)
    ├─→ [Select Date] → Patient Daily Summary
    │                       ↓
    │                   Patient Daily Summary Detail
    │                       (Shows: Cough count, SpO2, Heart rate, Temp for that day)
    │
    └─→ [Select Week] → Patient Weekly Summary
                            ↓
                        Patient Weekly Summary Detail
                            (Shows: Week trends, charts, comparisons)
```

**Files:**
- `patient_summary_page.dart`
- `patient_daily_summary.dart`
- `patient_daily_summary_detail.dart`
- `patient_weekly_summary.dart`
- `patient_weekly_summary_detail.dart`

---

### 7️⃣ Profile & Settings

```
Patient Profile
    ├─→ [Edit Medical Details] → Patient Edit Medical Details
    ├─→ [Edit Emergency Contact] → Patient Edit Emergency Contact
    ├─→ [View Medical Reports] → Patient View Medical Reports
    │                                ↓
    │                            Patient File Content (View specific file)
    └─→ [View Allergies] → Patient View Allergic Conditions
```

**Files:**
- `patient_profile.dart`
- `patient_edit_medical_details.dart`
- `patient_edit_emergency_contact.dart`
- `patient_view_medical_reports.dart`
- `patient_file_content.dart`
- `patient_view_allergic_conditions.dart`

---

### 8️⃣ Notifications

```
Patient Notifications
    ├─→ List of all notifications
    ├─→ Cough alerts
    ├─→ Doctor messages
    ├─→ Device status updates
    └─→ Appointment reminders
```

**File:** `patient_notifications.dart`

---

## 👨‍⚕️ DOCTOR NAVIGATION

### 1️⃣ Doctor Authentication Flow

```
Welcome Page
    ↓
Role Selection (Patient/Doctor)
    ↓
Doctor Login
    ├─→ [Login Button] → Doctor Home Page
    └─→ [Create Account Link] → Doctor Create Account
                                    ↓
                                Doctor More Details
                                    ↓
                                Doctor Verification Frame (Upload credentials)
                                    ↓
                                Doctor Verification Completed ✓
                                    ↓
                                Doctor Home Page
```

**Files:**
- `doctor_login_page.dart`
- `doctor_create_account_page.dart`
- `doctor_more_details_page.dart`
- `doctor_verification_frame.dart`
- `doctor_verification_completed.dart`

---

### 2️⃣ Doctor Home Page (Dashboard)

```
Doctor Home Page
    ├─→ [Profile Icon] → Doctor Profile Page
    ├─→ [Notifications Icon] → Doctor Notifications Page
    ├─→ [Patient Info Card] → Doctor Patient Info List/Empty
    ├─→ [Cough Analysis] → Doctor Cough Count
    └─→ [Bottom Nav]
            ├─→ Home (current)
            ├─→ Patients → Doctor Patient Info List
            └─→ Analytics → Doctor Summary
```

**File:** `doctor_home_page.dart`

---

### 3️⃣ Patient Management

```
Doctor Patient Info Empty (No patients yet)
    ↓
[Add Patient] → Doctor Patient Election (Select patient to connect)
    ↓
Doctor Patient Info List (All connected patients)
    ├─→ [Select Patient] → Doctor Realtime Patient (Live vitals)
    │                           ├─→ View cough count
    │                           ├─→ View daily summary
    │                           └─→ [Remove] → Doctor Remove Confirmation
    │
    ├─→ [View Report] → Doctor Select Report
    │                       ↓
    │                   Doctor View Report
    │
    └─→ [View Allergies] → Doctor Allergic Conditions
```

**Files:**
- `doctor_patient_info_empty.dart`
- `doctor_patient_election.dart`
- `doctor_patient_info_list.dart`
- `doctor_realtime_patient.dart`
- `doctor_remove_confirmation.dart`
- `doctor_select_report.dart`
- `doctor_view_report.dart`
- `doctor_allergic_conditions.dart`

---

### 4️⃣ Cough Analysis & Analytics

```
Doctor Cough Count (Patient cough analysis)
    ├─→ Real-time cough detection
    ├─→ Frequency analysis
    └─→ Type breakdown (Dry/Wet)

Doctor Summary (Statistics overview)
    ├─→ [Daily] → Doctor Daily Summary
    └─→ [Weekly] → Doctor Weekly Summary
```

**Files:**
- `doctor_cough_count.dart`
- `doctor_summary.dart`
- `doctor_daily_summary.dart`
- `doctor_weekly_summary.dart`

---

### 5️⃣ Doctor Profile

```
Doctor Profile Page
    ├─→ [Edit Details] → Doctor Edit Details
    ├─→ View specialization
    ├─→ View license number
    └─→ Connected patients count
```

**Files:**
- `doctor_profile_page.dart`
- `doctor_edit_details.dart`

---

## 🎯 Common Screens (Both Roles)

### Welcome & Role Selection

```
Welcome Page (App launch)
    ↓
Role Selection Page
    ├─→ [Patient] → Patient Login Page
    └─→ [Doctor] → Doctor Login Page
```

**Files:**
- `welcome_page.dart`
- `role_selection_page.dart`

---

### Additional Shared Screens

```
Cough Analyzer Screen (Detailed analysis tool)
    └─→ Can be accessed from both patient and doctor views

Device Screen (Device management)
    └─→ Shows connected devices
```

**Files:**
- `cough_analyzer_screen.dart`
- `device_screen.dart`
- `home_screen.dart` (General fallback home)

---

## 🔄 Navigation Patterns Used

### 1. **Push Navigation** (Go to new screen, keep previous in stack)
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```
**Used for:** Most screen transitions where user should be able to go back

---

### 2. **Push Replacement** (Replace current screen)
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```
**Used for:** Login → Home (no back to login), Account Created → Home

---

### 3. **Push and Remove Until** (Clear stack and go to screen)
```dart
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => HomeScreen()),
  (route) => false,
);
```
**Used for:** Logout, Complete registration flows

---

### 4. **Pop** (Go back to previous screen)
```dart
Navigator.pop(context);
```
**Used for:** Back button, Cancel actions, Close dialogs

---

## 📊 Navigation Statistics

### Patient Pages: **36 screens**
- Authentication: 7 screens
- Home & Dashboard: 1 screen
- Device Connection: 7 screens
- Doctor Connection: 7 screens
- Cough Monitoring: 1 screen
- Summaries: 5 screens
- Profile: 6 screens
- Notifications: 1 screen
- Miscellaneous: 1 screen

### Doctor Pages: **23 screens**
- Authentication: 5 screens
- Home & Dashboard: 1 screen
- Patient Management: 9 screens
- Analytics: 4 screens
- Reports: 3 screens
- Profile: 2 screens
- Notifications: 1 screen

### Common Pages: **3 screens**
- Welcome: 1 screen
- Role Selection: 1 screen
- General Home: 1 screen

### **Total: 62 screens** ✅

---

## 🧪 Testing Navigation

### To test the complete patient flow:

1. Start app → Welcome Page
2. Tap "Get Started" → Role Selection
3. Tap "Patient" → Patient Login
4. Tap "Create Account" → Goes through all 5 registration steps
5. Completes at Patient Home Screen
6. From Home:
   - Tap profile icon → Patient Profile
   - Tap notifications → Patient Notifications
   - Tap cough card → Patient Cough Count
   - Tap Device tab → Connect Device Flow
   - Tap Trends tab → Summary Pages

---

### To test the complete doctor flow:

1. Start app → Welcome Page
2. Tap "Get Started" → Role Selection
3. Tap "Doctor" → Doctor Login
4. Tap "Create Account" → Goes through 4 verification steps
5. Completes at Doctor Home Page
6. From Home:
   - View patients → Patient Management
   - View analytics → Summary pages
   - Access reports → Patient reports

---

## 💡 Quick Navigation Tips

1. **All bottom navigation bars** have 3 tabs for easy access
2. **All screens have back buttons** in app bar (except home screens)
3. **Profile and notifications** accessible from top bar icons
4. **Modals and dialogs** can be dismissed with back button
5. **Account creation flows** guide user step-by-step with "Continue" buttons

---

## 🔗 File Organization

Current structure (flat):
```
lib/screens/
├── welcome_page.dart
├── role_selection_page.dart
├── patient_*.dart (36 files)
├── doctor_*.dart (23 files)
└── other screens (3 files)
```

Recommended structure (organized):
```
lib/screens/
├── common/
│   ├── welcome_page.dart
│   ├── role_selection_page.dart
│   └── home_screen.dart
├── patient/
│   ├── auth/ (7 files)
│   ├── home/ (2 files)
│   ├── device/ (7 files)
│   ├── doctor/ (7 files)
│   ├── analytics/ (6 files)
│   └── profile/ (7 files)
└── doctor/
    ├── auth/ (5 files)
    ├── home/ (2 files)
    ├── patients/ (9 files)
    ├── analytics/ (4 files)
    └── profile/ (3 files)
```

---

## ✅ All Pages Are Connected!

Every page in the app can be reached through navigation from the welcome screen. No orphaned pages! 🎉

**Last Updated:** January 7, 2026
