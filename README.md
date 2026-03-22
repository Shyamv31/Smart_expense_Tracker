# 💰 Smart Expense Tracker

<div align="center">


A powerful and intelligent expense tracking mobile application built with Flutter & Firebase

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
[![Gemini AI](https://img.shields.io/badge/Gemini-AI-green.svg)](https://ai.google.dev)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)

</div>

## ✨ Features

### 💸 Expense & Income Tracking
- Add expenses and income with categories
- Payment modes: Cash, Card, UPI, Net Banking
- Voice input in **Tamil & English**
- Edit and delete transactions
- Swipe to delete with confirmation

### 📊 Reports & Analytics
- Income vs Expense comparison cards
- Savings calculation
- **Pie chart** by spending category
- **Weekly bar chart** visualization
- Month-by-month navigation

### 🤖 AI-Powered Features
- **Receipt Scanner** using Google Gemini AI
- Auto-fills title, amount and category from receipt photo
- Smart spending advice
- Expense prediction

### 📱 SMS Auto-Detection
- Automatically reads bank transaction SMS
- Supports GPay, PhonePe, Paytm, all banks
- Manual scan for last 7 days
- Auto-categorizes transactions

### 🎯 Savings Goals
- Set financial goals (Car, Home, Trip etc.)
- Track progress with visual progress bar
- Add money to goals
- Days remaining countdown
- 10+ goal templates

### 🔄 Recurring Expenses
- Set daily/weekly/monthly recurring expenses
- Auto-adds when due date arrives
- Toggle ON/OFF anytime
- Next due date tracking

### 🔔 Notifications
- Daily reminder to log expenses
- User-defined reminder time
- Budget exceeded alerts

### 🌙 UI/UX
- Beautiful splash screen animation
- Dark mode support
- Smooth page transitions
- Sidebar drawer navigation
- Responsive design

### 🔐 Security & Sync
- Firebase Authentication
- Google Sign-In
- Real-time Cloud Firestore sync
- Auto login on app restart
- Email validation

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| **Flutter & Dart** | Cross-platform mobile development |
| **Firebase Auth** | User authentication |
| **Cloud Firestore** | Real-time database |
| **Google Gemini AI** | Receipt scanning & AI advice |
| **Provider** | State management |
| **FL Chart** | Data visualization |
| **flutter_local_notifications** | Push notifications |
| **speech_to_text** | Voice input |
| **image_picker** | Camera & gallery access |
| **google_sign_in** | Google authentication |

---

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── expense_model.dart       # Expense data model
│   ├── goal_model.dart          # Savings goal model
│   └── recurring_expense_model.dart
├── screens/
│   ├── login_screen.dart        # Login screen
│   ├── register_screen.dart     # Register screen
│   ├── home_screen.dart         # Home dashboard
│   ├── add_expense_screen.dart  # Add expense/income
│   ├── history_screen.dart      # Transaction history
│   ├── reports_screen.dart      # Analytics & reports
│   ├── recurring_expense_screen.dart
│   ├── goals_screen.dart        # Savings goals
│   └── settings_screen.dart    # App settings
├── services/
│   ├── auth_service.dart        # Authentication
│   ├── expense_service.dart     # Expense CRUD
│   ├── gemini_service.dart      # AI features
│   ├── notification_service.dart
│   ├── recurring_expense_service.dart
│   ├── sms_service.dart         # SMS detection
│   └── theme_provider.dart      # Dark mode
└── utils/
    └── constants.dart           # App constants
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Android Studio / VS Code
- Firebase account
- Google Gemini API key

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/Shyamv31/Smart_expense_Tracker.git
cd Smart_expense_Tracker
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable Authentication (Email/Password + Google)
   - Create Cloud Firestore database
   - Download `google-services.json` and place in `android/app/`

4. **Setup Gemini API**
   - Get API key from [aistudio.google.com](https://aistudio.google.com)
   - Create `.env` file in root:
```
GEMINI_API_KEY=your_api_key_here
```

5. **Run the app**
```bash
flutter run
```

### Build Release APK
```bash
flutter build apk --release
```
APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## 🔧 Configuration

### Firebase Setup
- Enable **Email/Password** authentication
- Enable **Google Sign-In** authentication
- Add SHA-1 fingerprint for Google Sign-In
- Create Firestore database in **asia-south1** region

### Permissions Required
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_SMS"/>
<uses-permission android:name="android.permission.READ_SMS"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

---


## 🏫 About


The app solves the real-world problem of expense tracking for students and working professionals in India, with special focus on:
- Indian payment methods (UPI, GPay, PhonePe)
- Tamil language voice support
- Indian Rupee (₹) currency
- SMS detection from Indian banks

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

- [Flutter](https://flutter.dev) - Amazing cross-platform framework
- [Firebase](https://firebase.google.com) - Backend infrastructure
- [Google Gemini AI](https://ai.google.dev) - AI capabilities
- [FL Chart](https://pub.dev/packages/fl_chart) - Beautiful charts

---

<div align="center">
Made with ❤️ in India 🇮🇳

⭐ Star this repo if you found it helpful!
</div>
