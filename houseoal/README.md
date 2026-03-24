# HousePal - Ứng dụng Quản lý Nhà trọ

> Lưu ý: Backend .NET API đã được loại bỏ khỏi repository; hiện tại app dùng trực tiếp Firebase (Firestore, Auth, Storage) để lưu trữ và đồng bộ dữ liệu.

## Giới thiệu
HousePal là một ứng dụng di động Flutter giúp quản lý cuộc sống chung trong nhà trọ/chung cư một cách hiệu quả, minh bạch và công bằng.

## Tính năng Chính

### 1. Lịch Việc Nhà (Chore Wheel)
- Tạo và quản lý các công việc nhà lặp lại
- Tự động xoay vòng việc cho các thành viên
- Xác nhận hoàn thành công việc
- Hệ thống điểm gamification
- Bảng xếp hạng tháng

### 2. Quỹ Chung & Chia Tiền (Shared Wallet)
- Thêm chi tiêu và theo dõi
- Chia tiền linh hoạt (đều, theo tỷ lệ, theo người)
- Bảng cân đối "Ai nợ Ai"
- Tối giản nợ tự động
- Xác nhận thanh toán

### 3. Bảng Tin Chung (Bulletin Board)
- Ghi chú chung (ghim thông tin quan trọng)
- Danh sách mua sắm chia sẻ
- Lịch sử mua sắm

## Cài đặt

### Yêu cầu
- Flutter 3.0+
- Dart 3.0+
- Firebase project

### Bước 1: Clone hoặc tải dự án
```bash
cd houseoal
```

### Bước 2: Cài đặt dependencies
```bash
flutter pub get
```

### Bước 3: Cấu hình Firebase
1. Tạo một Firebase project tại https://console.firebase.google.com
2. Thêm ứng dụng iOS và Android vào project
3. Download các file cấu hình:
   - `GoogleService-Info.plist` cho iOS → `ios/Runner/GoogleService-Info.plist`
   - `google-services.json` cho Android → `android/app/google-services.json`

### Bước 4: Chạy ứng dụng
```bash
flutter run
```

## Cấu trúc Dự án

```
lib/
├── config/              # Cấu hình ứng dụng
│   └── app_theme.dart   # Cấu hình chủ đề
├── models/              # Các lớp dữ liệu
│   ├── user_model.dart
│   ├── household_model.dart
│   ├── chore_model.dart
│   ├── expense_model.dart
│   └── bulletin_model.dart
├── services/            # Các dịch vụ (Firebase)
│   ├── auth_service.dart
│   ├── chore_service.dart
│   ├── expense_service.dart
│   └── bulletin_service.dart
├── providers/           # Riverpod providers
│   ├── auth_provider.dart
│   ├── chore_provider.dart
│   ├── expense_provider.dart
│   └── bulletin_provider.dart
├── screens/             # Các màn hình UI
│   ├── auth/            # Login, Register
│   ├── home/            # Trang chủ
│   ├── chores/          # Quản lý công việc nhà
│   ├── expenses/        # Quản lý chi phí
│   └── bulletin/        # Bảng tin
├── widgets/             # Custom widgets
└── utils/               # Utility functions
└── main.dart            # Entry point
```

## Các Tính Năng Sắp Tới
- [ ] Thông báo push theo thời gian thực
- [ ] Chi tiết công việc và lịch sử
- [ ] Form tạo/chỉnh sửa công việc
- [ ] Form thêm chi tiêu
- [ ] Hồ sơ người dùng
- [ ] Cài đặt ứng dụng
- [ ] Export/Import dữ liệu
- [ ] Chế độ tối

## Firebase Security Rules

### Firestore Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    match /households/{householdId} {
      allow read: if request.auth.uid in resource.data.memberIds;
      allow write: if request.auth.uid == resource.data.adminId;
    }
    
    match /chores/{choreId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
      allow write: if request.auth.uid == get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.adminId;
    }
    
    match /expenses/{expenseId} {
      allow read, write: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
    }
    
    match /bulletin_notes/{noteId} {
      allow read: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
      allow write: if request.auth.uid == resource.data.createdBy;
    }
    
    match /shopping_list/{itemId} {
      allow read, write: if request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.memberIds;
    }
  }
}
```

## Hướng Dẫn Sử Dụng

### Lần Đầu Tiên
1. Mở ứng dụng
2. Chọn "Đăng Ký"
3. Nhập thông tin cá nhân và tạo nhà trọ mới
4. Bạn sẽ trở thành Admin và có thể mời các thành viên khác

### Quản lý Công Việc Nhà
1. Vào tab "Công việc"
2. Bấm "+" để tạo công việc mới
3. Điền tên, mô tả, điểm số, tần suất
4. Chọn các thành viên sẽ thay phiên nhau làm
5. Khi hoàn thành, bấm "Hoàn thành"

### Quản lý Chi Phí
1. Vào tab "Chi phí"
2. Bấm "+" để thêm chi tiêu
3. Chọn cách chia tiền
4. Xem bảng cân đối để biết ai nợ ai bao nhiêu
5. Xác nhận thanh toán khi đã trả

## Đóng góp
Nếu bạn muốn đóng góp vào dự án, vui lòng tạo một pull request.

## Giấy phép
Dự án này được cấp phép theo MIT License.
