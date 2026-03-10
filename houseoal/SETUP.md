# HousePal - Hướng Dẫn Chi Tiết Thiết Lập

## 1. Cài Đặt Môi Trường

### Yêu cầu Hệ Thống
- Flutter SDK 3.0.0 hoặc cao hơn
- Dart 3.0.0 hoặc cao hơn
- Android SDK (API level 21+) cho Android
- Xcode 12+ cho iOS
- Java Development Kit (JDK) 11+

### Cài đặt Flutter
```bash
# Download Flutter
git clone https://github.com/flutter/flutter.git

# Thêm Flutter vào PATH
export PATH="$PATH:[your-flutter-path]/flutter/bin"

# Kiểm tra cài đặt
flutter doctor
```

## 2. Cấu Hình Firebase

### Bước 1: Tạo Firebase Project
1. Truy cập https://console.firebase.google.com
2. Nhấp "Create a new project"
3. Nhập tên: "HousePal"
4. Chọn quốc gia
5. Nhấp "Create project"

### Bước 2: Thêm Ứng dụng Android
1. Nhấp "Add app" → chọn "Android"
2. Package name: `com.example.housepal`
3. Debug SHA-1: Chạy `./gradlew signingReport` trong folder android
4. Download `google-services.json`
5. Copy vào `android/app/google-services.json`

### Bước 3: Thêm Ứng dụng iOS
1. Nhấp "Add app" → chọn "iOS"
2. Bundle ID: `com.example.housepal`
3. Download `GoogleService-Info.plist`
4. Copy vào `ios/Runner/GoogleService-Info.plist`
5. Thêm file vào Xcode project (right-click → Add Files to Runner)

### Bước 4: Bật Firestore
1. Vào Firebase Console → Firestore Database
2. Nhấp "Create database"
3. Chọn "Start in test mode"
4. Chọn vị trí gần nhất
5. Nhấp "Enable"

### Bước 5: Bật Authentication
1. Vào Firebase Console → Authentication
2. Nhấp "Get started"
3. Chọn "Email/Password"
4. Bật cả "Email/Password" và "Email link (passwordless sign-in)"
5. Nhấp "Save"

## 3. Cài Đặt Dự Án

### Clone và Setup
```bash
# Clone dự án
git clone [your-repo-url] houseoal
cd houseoal

# Cài đặt dependencies
flutter pub get

# Build generated files
flutter pub run build_runner build
```

### Chạy Ứng Dụng
```bash
# Chạy trên iOS
flutter run -d ios

# Chạy trên Android
flutter run -d android

# Chạy trên web (nếu được hỗ trợ)
flutter run -d web

# Chạy với mode release
flutter run --release
```

## 4. Cấu Hình Firestore Security Rules

Thay thế Security Rules mặc định bằng:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Households collection
    match /households/{householdId} {
      allow read: if request.auth.uid in resource.data.memberIds;
      allow create: if request.auth.uid != null;
      allow update, delete: if request.auth.uid == resource.data.adminId;
    }
    
    // Chores
    match /chores/{choreId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
      allow write: if request.auth.uid == get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.adminId;
    }
    
    // Chore Completions
    match /chore_completions/{completionId} {
      allow read, create: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
    }
    
    // Expenses
    match /expenses/{expenseId} {
      allow read, write: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
    }
    
    // Payments
    match /payments/{paymentId} {
      allow read, create: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
    }
    
    // Bulletin Notes
    match /bulletin_notes/{noteId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
      allow create, update: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
      allow delete: if request.auth.uid == resource.data.createdBy;
    }
    
    // Shopping List
    match /shopping_list/{itemId} {
      allow read, create, update: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
      allow delete: if request.auth.uid == resource.data.createdBy || request.auth.uid == resource.data.purchasedBy;
    }
  }
}
```

## 5. Cấu Hình iOS

### Yêu cầu
- iOS 11.0 trở lên
- Xcode 12.0 trở lên
- CocoaPods

### Các bước
```bash
# Cài CocoaPods (nếu chưa)
sudo gem install cocoapods

# Cài đặt dependencies
cd ios
pod install
cd ..
```

## 6. Cấu Hình Android

### Yêu cầu
- Android API level 21+ (Android 5.0)
- Android Studio

### Các bước
```bash
# Chạy Android setup
flutter pub run build_runner build
```

## 7. Build APK/AAB

### Build APK (Debug)
```bash
flutter build apk --debug
# Output: build/app/outputs/apk/debug/app-debug.apk
```

### Build APK (Release)
```bash
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

### Build Bundle (Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

## 8. Build iOS App

```bash
# Build iOS
flutter build ios --release

# Để submit lên App Store, mở file ios/Runner.xcworkspace trong Xcode
```

## 9. Kiểm Tra Và Debug

### Run Tests
```bash
flutter test
```

### Kiểm tra Code Issues
```bash
flutter analyze
```

### Format Code
```bash
dart format lib/
```

## 10. Các Lệnh Hữu Ích

```bash
# Xem các devices khả dụng
flutter devices

# Clean build
flutter clean

# Cài đặt lại dependencies
flutter pub get
flutter pub upgrade

# Hot reload
flutter run

# Hot restart
Shift + R (trong terminal khi đang chạy)

# Profile mode
flutter run --profile

# Release mode
flutter run --release
```

## Troubleshooting

### Lỗi: "Could not find com.google.firebase:firebase-core"
- Kiểm tra `android/build.gradle` có các dependencies Firebase
- Chạy `flutter pub get` lại

### Lỗi: "Could not build Dart code for darwin"
- Chạy `flutter clean`
- Chạy `flutter pub get`
- Chạy `pod install` trong folder ios

### Lỗi: "error: The sandbox is not in sync with the Podfile.lock"
- Chạy `cd ios && pod install && cd ..`

### App không connect Firebase
- Kiểm tra `google-services.json` và `GoogleService-Info.plist` đã copy đúng chỗ
- Kiểm tra Firebase project ID khớp
- Kiểm tra Firestore đã bật

## Tài Liệu Tham Khảo
- [Flutter Docs](https://flutter.dev/docs)
- [Firebase Flutter Plugin](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Google Fonts Package](https://pub.dev/packages/google_fonts)
