# HousePal Backend Setup Guide

Backend đã được tạo với **ASP.NET Core 8.0 + SQL Server** theo đúng yêu cầu dự án.

## 📁 Cấu trúc Backend

```
C:\Users\DELL\Desktop\HousePalAPI/
├── Models/                      # Entity classes (11 models)
│   ├── User.cs                 # Người dùng/Thành viên
│   ├── House.cs                # Ngôi nhà/Căn hộ chung
│   ├── Chore.cs                # Công việc nhà
│   ├── ChoreAssignment.cs      # Phân công việc
│   ├── ChoreCompletion.cs      # Ghi nhận hoàn thành
│   ├── Expense.cs              # Chi tiêu chung
│   ├── ExpenseSplit.cs         # Chi tiết chia chi tiêu
│   ├── Debt.cs                 # Bảng nợ "Ai nợ Ai"
│   ├── Note.cs                 # Ghi chú chung
│   ├── ShoppingItem.cs         # Danh sách mua sắm
│   └── Notification.cs         # Thông báo
├── Data/
│   └── HousePalDbContext.cs    # Entity Framework DbContext
├── Controllers/
│   └── UsersController.cs      # API skeleton (cần mở rộng)
├── Program.cs                   # Entry point + DI setup
├── appsettings.json            # Configuration + Connection String
├── Database_Schema.sql         # SQL script tạo database
└── BACKEND_README.md           # Documentation

Frontend: /lib (Flutter)
```

## 🗄️ Database Schema (11 Tables)

### FR1: Module "Lịch Việc nhà" (Chore Wheel)
- **Chores** - Danh sách công việc nhà với điểm, tần suất
- **ChoreAssignments** - Phân công việc cho từng thành viên
- **ChoreCompletions** - Ghi nhận hoàn thành & điểm tích lũy

### FR2: Module "Quỹ chung & Chia tiền" (Shared Wallet & Splitter)
- **Expenses** - Chi tiêu chung (điện, nước, đi chợ, v.v)
- **ExpenseSplits** - Chi tiết chia: ai nợ bao nhiêu
- **Debts** - Bảng tối giản nợ "Ai nợ Ai"

### FR3: Module "Bảng tin Chung" (House Bulletin)
- **Notes** - Ghi chú/Thông báo ghim (Wifi, số ĐT chủ nhà)
- **ShoppingItems** - Danh sách mua sắm chung

### Core
- **Houses** - Ngôi nhà/Căn hộ (mã code để join)
- **Users** - Thành viên (admin/member)
- **Notifications** - Thông báo real-time

## ⚙️ Thiết lập & Chạy Backend

### Bước 1: Kiểm tra SQL Server
```bash
# Bật SQL Server nếu chưa bật
# Hoặc dùng SQL Server Express Local DB
```

### Bước 2: Tạo Database (Chọn 1 trong 2 cách)

**Cách A: Dùng SQL Script (Recommended)**
```bash
# Mở SQL Server Management Studio
# Tạo new query → Paste nội dung Database_Schema.sql
# Execute (F5)
```

**Cách B: Dùng Entity Framework Migrations**
```bash
cd C:\Users\DELL\Desktop\HousePalAPI

# Tạo initial migration
dotnet ef migrations add InitialCreate

# Áp dụng migration vào database
dotnet ef database update
```

### Bước 3: Chạy Backend API

```bash
cd C:\Users\DELL\Desktop\HousePalAPI

# Build project
dotnet build

# Chạy API
dotnet run

# API sẽ chạy tại:
# - https://localhost:5001 (HTTPS)
# - http://localhost:5000 (HTTP)
# - Swagger UI: http://localhost:5000/swagger
```

## 🔌 Kết nối Frontend (Flutter) với Backend

Trong Flutter app, cập nhật API base URL:

```dart
// lib/services/api_service.dart
const String API_BASE_URL = 'http://YOUR_COMPUTER_IP:5000/api';
// Hoặc 'http://localhost:5000/api' nếu chạy trên máy tính
```

## 📋 API Endpoints (To-do)

Cần implement các controllers sau:

### Users
- [ ] `GET /api/users` - Lấy danh sách người dùng
- [ ] `GET /api/users/{id}` - Chi tiết user
- [ ] `POST /api/users` - Tạo user mới
- [ ] `PUT /api/users/{id}` - Cập nhật user
- [ ] `DELETE /api/users/{id}` - Xóa user

### Houses
- [ ] `GET /api/houses` - Danh sách nhà
- [ ] `GET /api/houses/{id}` - Chi tiết nhà
- [ ] `POST /api/houses` - Tạo nhà mới
- [ ] `POST /api/houses/{id}/members` - Thêm thành viên
- [ ] `GET /api/houses/{id}/members` - Danh sách thành viên

### Chores
- [ ] `GET /api/houses/{id}/chores` - Danh sách công việc
- [ ] `POST /api/chores` - Tạo công việc mới
- [ ] `POST /api/chores/{id}/assignments` - Phân công
- [ ] `POST /api/chores/{id}/complete` - Đánh dấu hoàn thành
- [ ] `GET /api/houses/{id}/leaderboard` - Xếp hạng theo điểm

### Expenses
- [ ] `GET /api/houses/{id}/expenses` - Danh sách chi tiêu
- [ ] `POST /api/expenses` - Thêm chi tiêu mới
- [ ] `GET /api/houses/{id}/balance` - Bảng "Ai nợ Ai"
- [ ] `POST /api/debts/{id}/settle` - Thanh toán nợ
- [ ] `GET /api/users/{id}/debts` - Nợ của user

### Notes
- [ ] `GET /api/houses/{id}/notes` - Ghi chú chung
- [ ] `POST /api/notes` - Tạo ghi chú
- [ ] `PUT /api/notes/{id}/pin` - Ghim ghi chú
- [ ] `DELETE /api/notes/{id}` - Xóa ghi chú

### Shopping Items
- [ ] `GET /api/houses/{id}/shopping-items` - Danh sách mua sắm
- [ ] `POST /api/shopping-items` - Thêm item
- [ ] `PUT /api/shopping-items/{id}/mark-done` - Đánh dấu mua
- [ ] `DELETE /api/shopping-items/{id}` - Xóa item

### Notifications
- [ ] `GET /api/users/{id}/notifications` - Thông báo của user
- [ ] `PUT /api/notifications/{id}/read` - Đánh dấu đã đọc
- [ ] `DELETE /api/notifications/{id}` - Xóa thông báo

## 📊 Database Relationships

```
Houses (1) ───→ (N) Users
Houses (1) ───→ (N) Chores
Houses (1) ───→ (N) Expenses
Houses (1) ───→ (N) Debts
Houses (1) ───→ (N) Notes
Houses (1) ───→ (N) ShoppingItems

Chores (1) ───→ (N) ChoreAssignments
ChoreAssignments (1) ───→ (N) ChoreCompletions
Users (1) ───→ (N) ChoreAssignments
Users (1) ───→ (N) ChoreCompletions

Expenses (1) ───→ (N) ExpenseSplits
Users (1) ───→ (N) Expenses (PaidBy)
Users (1) ───→ (N) ExpenseSplits

Users (1) ───→ (N) Debts (AsDebtor)
Users (1) ───→ (N) Debts (AsCreditor)

Users (1) ───→ (N) Notifications
```

## 🔐 CORS Configuration

Backend đã config CORS để Flask app có thể gọi API:
```csharp
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFlutterApp",
        builder =>
        {
            builder
                .AllowAnyOrigin()
                .AllowAnyMethod()
                .AllowAnyHeader();
        });
});
```

## 🛠️ Technologies Used

- **Framework**: ASP.NET Core 8.0
- **Language**: C#
- **Database**: SQL Server
- **ORM**: Entity Framework Core 8.0
- **API Pattern**: RESTful
- **Package Manager**: NuGet

## 📝 Tiếp theo

1. **Implement Controllers** - Tạo đầy đủ các API endpoints
2. **Add Services** - Business logic layer
3. **Add Authentication** - JWT tokens
4. **Add Validation** - Data validation
5. **Add Error Handling** - Exception handling
6. **Add Logging** - Serilog hoặc tương tự
7. **Add Unit Tests** - xUnit
8. **Deploy** - Azure, AWS hoặc server

## 📞 Liên hệ

Dự án HousePal - "Ngôi nhà Chung"
Trợ lý quản lý nhà trọ/chung cư
