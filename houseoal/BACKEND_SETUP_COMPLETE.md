# HousePal Backend Setup Complete ✅

**Created**: ASP.NET Core 8.0 Web API Backend for HousePal

## 📂 Backend Location
```
C:\Users\DELL\Desktop\HousePalAPI/
```

## ✨ What Was Created

### 1. **11 Entity Models** (Database Tables)
- ✅ **User.cs** - Thành viên nhà
- ✅ **House.cs** - Ngôi nhà/Căn hộ
- ✅ **Chore.cs** - Công việc nhà
- ✅ **ChoreAssignment.cs** - Phân công việc
- ✅ **ChoreCompletion.cs** - Ghi nhận hoàn thành
- ✅ **Expense.cs** - Chi tiêu chung
- ✅ **ExpenseSplit.cs** - Chi tiết chia chi tiêu
- ✅ **Debt.cs** - Bảng "Ai nợ Ai"
- ✅ **Note.cs** - Ghi chú chung
- ✅ **ShoppingItem.cs** - Danh sách mua sắm
- ✅ **Notification.cs** - Thông báo

### 2. **Entity Framework DbContext**
- ✅ **HousePalDbContext.cs** - Toàn bộ relationships được configure

### 3. **Database Schema**
- ✅ **Database_Schema.sql** - SQL script tạo 11 tables + indexes

### 4. **Project Structure**
```
HousePalAPI/
├── Models/              (11 Entity Models)
├── Data/                (DbContext)
├── Controllers/         (API Skeleton)
├── Program.cs           (DI + CORS Setup)
├── appsettings.json     (Connection String)
├── Database_Schema.sql  (SQL Script)
├── SETUP_GUIDE.md       (Hướng dẫn chi tiết)
└── BACKEND_README.md    (Documentation)
```

## 🗄️ Database Schema

### FR1: Module "Lịch Việc nhà" (Chore Wheel)
```
Chores
  ├─ ChoreAssignments (phân công)
  └─ ChoreCompletions (ghi nhận hoàn thành + điểm)
```

### FR2: Module "Quỹ chung & Chia tiền" (Shared Wallet & Splitter)
```
Expenses
  ├─ ExpenseSplits (ai nợ bao nhiêu)
  └─ Debts (tối giản nợ "Ai nợ Ai")
```

### FR3: Module "Bảng tin Chung" (House Bulletin)
```
Notes
ShoppingItems
```

### Core
```
Houses
  ├─ Users (thành viên)
  ├─ Chores
  ├─ Expenses
  ├─ Debts
  ├─ Notes
  └─ ShoppingItems

Notifications (for real-time updates)
```

## 🚀 Quick Start

### 1️⃣ Create Database
```bash
# Option 1: SQL Script
# Mở SQL Server Management Studio → Execute Database_Schema.sql

# Option 2: EF Migrations
cd C:\Users\DELL\Desktop\HousePalAPI
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### 2️⃣ Update Connection String (appsettings.json)
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SERVER;Database=HousePalDB;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

### 3️⃣ Run Backend
```bash
cd C:\Users\DELL\Desktop\HousePalAPI
dotnet run

# API: http://localhost:5000
# Swagger: http://localhost:5000/swagger
```

### 4️⃣ Connect Flutter App
Update in Flutter:
```dart
const String API_BASE_URL = 'http://localhost:5000/api';
```

## 📋 API Endpoints Status

### Currently Implemented
- ✅ Basic project structure
- ✅ DbContext configured
- ✅ Models with relationships
- ✅ UsersController skeleton
- ✅ CORS setup for Flutter

### Need to Implement
- ⏳ Complete all Controllers (Users, Houses, Chores, Expenses, etc.)
- ⏳ Business logic services
- ⏳ Authentication (JWT)
- ⏳ Real-time notifications (WebSocket)
- ⏳ Input validation
- ⏳ Error handling
- ⏳ Unit tests

## 📌 Key Features Ready in Database

✅ **FR1 Support**: Chore rotation system with points gamification
✅ **FR2 Support**: Flexible expense splitting (equal/custom/people) + debt optimization  
✅ **FR3 Support**: Shared notes/bulletin + shopping list
✅ **Real-time**: Notifications table ready for push notifications

## 🔗 Integration Points

### Frontend → Backend
```
Flutter App (localhost:5000)
    ↓
ASP.NET Core API (localhost:5000)
    ↓
SQL Server (HousePalDB)
```

### CORS Configured
- ✅ Allows requests from any origin (for development)
- ✅ Production: update CORS policy with specific frontend URLs

## 📚 Documentation Files

- **SETUP_GUIDE.md** - Step-by-step setup instructions
- **BACKEND_README.md** - Full API documentation
- **Database_Schema.sql** - Database creation script

## ⚠️ Important Notes

1. **SQL Server Required**: Ensure SQL Server 2019+ is installed
2. **Connection String**: Update with your server name
3. **Windows Auth**: Using Trusted_Connection=True (Windows Authentication)
4. **CORS**: Currently open for all origins (development mode)

## 🎯 Next Steps

1. Create SQL Server database using Database_Schema.sql
2. Update connection string in appsettings.json
3. Implement remaining Controllers (copy UsersController.cs pattern)
4. Add services layer for business logic
5. Add JWT authentication
6. Connect Flutter app to backend API

## 📞 Tech Stack

- **Framework**: ASP.NET Core 8.0
- **Language**: C#
- **Database**: SQL Server
- **ORM**: Entity Framework Core 8.0
- **API Style**: RESTful
- **Frontend**: Flutter (Dart)

---

**Status**: ✅ Backend Ready for Development
**Next**: Implement API Controllers & Services
