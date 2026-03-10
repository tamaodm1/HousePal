# HousePal Backend API

ASP.NET Core 8.0 Web API cho ứng dụng quản lý nhà trọ/chung cư HousePal.

## Kiến trúc Database

### Entities (Database Tables):

1. **Houses** - Ngôi nhà/căn hộ chung
2. **Users** - Thành viên trong nhà
3. **Chores** - Danh sách công việc nhà
4. **ChoreAssignments** - Phân công việc nhà từng tuần/tháng
5. **ChoreCompletions** - Ghi nhận hoàn thành công việc & điểm
6. **Expenses** - Chi tiêu chung
7. **ExpenseSplits** - Chi tiết chia chi tiêu (Ai nợ bao nhiêu)
8. **Debts** - Bảng "Ai nợ Ai" (tối giản nợ)
9. **Notes** - Ghi chú chung (Wifi, số ĐT chủ nhà, v.v)
10. **ShoppingItems** - Danh sách mua sắm
11. **Notifications** - Thông báo

## Thiết lập

### Yêu cầu
- .NET 8.0 SDK
- SQL Server 2019+ hoặc SQL Server Express

### Cài đặt

1. **Cài đặt dependencies:**
```bash
cd HousePalAPI
dotnet restore
```

2. **Cập nhật appsettings.json** với connection string SQL Server:
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=YOUR_SERVER;Database=HousePalDB;Trusted_Connection=True;TrustServerCertificate=True;"
  }
}
```

3. **Tạo Database Migration:**
```bash
dotnet ef migrations add InitialCreate
```

4. **Áp dụng Migration vào Database:**
```bash
dotnet ef database update
```

5. **Chạy API:**
```bash
dotnet run
```

API sẽ chạy tại `https://localhost:5001` hoặc `http://localhost:5000`

## API Endpoints (Skeleton)

### Users
- `GET /api/users` - Lấy danh sách người dùng
- `GET /api/users/{id}` - Lấy chi tiết user
- `POST /api/users` - Tạo user mới

### Houses
- `GET /api/houses` - Lấy danh sách nhà
- `POST /api/houses` - Tạo nhà mới
- `POST /api/houses/{id}/members` - Thêm thành viên

### Chores
- `GET /api/houses/{id}/chores` - Lấy danh sách công việc
- `POST /api/chores` - Tạo công việc mới
- `POST /api/chores/{id}/complete` - Đánh dấu hoàn thành

### Expenses
- `GET /api/houses/{id}/expenses` - Lấy danh sách chi tiêu
- `POST /api/expenses` - Thêm chi tiêu mới
- `GET /api/houses/{id}/balance` - Lấy bảng "Ai nợ Ai"

### Notes
- `GET /api/houses/{id}/notes` - Lấy ghi chú chung
- `POST /api/notes` - Tạo ghi chú mới

### Shopping Items
- `GET /api/houses/{id}/shopping-items` - Lấy danh sách mua sắm
- `POST /api/shopping-items` - Thêm mục mua sắm

### Notifications
- `GET /api/users/{id}/notifications` - Lấy thông báo
- `PUT /api/notifications/{id}/read` - Đánh dấu đã đọc

## Folder Structure

```
HousePalAPI/
├── Models/              # Entity classes
│   ├── User.cs
│   ├── House.cs
│   ├── Chore.cs
│   ├── ChoreAssignment.cs
│   ├── ChoreCompletion.cs
│   ├── Expense.cs
│   ├── ExpenseSplit.cs
│   ├── Debt.cs
│   ├── Note.cs
│   ├── ShoppingItem.cs
│   └── Notification.cs
├── Data/                # DbContext
│   └── HousePalDbContext.cs
├── Controllers/         # API Controllers
│   ├── UsersController.cs
│   ├── HousesController.cs
│   ├── ChoresController.cs
│   ├── ExpensesController.cs
│   ├── NotesController.cs
│   └── ShoppingItemsController.cs
├── Migrations/          # EF Core Migrations
├── Program.cs           # Entry point & DI setup
├── appsettings.json     # Configuration
└── HousePalAPI.csproj   # Project file
```

## Database Schema

### Users Table
```sql
CREATE TABLE Users (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL,
    PhoneNumber NVARCHAR(20),
    HouseId INT NOT NULL,
    IsAdmin BIT NOT NULL DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME DEFAULT GETUTCDATE(),
    FOREIGN KEY (HouseId) REFERENCES Houses(Id)
)
```

### Houses Table
```sql
CREATE TABLE Houses (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    JoinCode NVARCHAR(20) NOT NULL UNIQUE,
    MemberCount INT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME DEFAULT GETUTCDATE()
)
```

### Expenses Table
```sql
CREATE TABLE Expenses (
    Id INT PRIMARY KEY IDENTITY(1,1),
    HouseId INT NOT NULL,
    PaidByUserId INT NOT NULL,
    Description NVARCHAR(100) NOT NULL,
    Amount DECIMAL(10,2) NOT NULL,
    Category NVARCHAR(20) DEFAULT 'other',
    SplitType NVARCHAR(20) DEFAULT 'equal',
    CreatedAt DATETIME DEFAULT GETUTCDATE(),
    UpdatedAt DATETIME DEFAULT GETUTCDATE(),
    FOREIGN KEY (HouseId) REFERENCES Houses(Id),
    FOREIGN KEY (PaidByUserId) REFERENCES Users(Id)
)
```

## Features Phát triển tiếp

- [ ] Authentication (JWT)
- [ ] Real-time notifications (WebSocket)
- [ ] Debt optimization algorithm
- [ ] Monthly settlement reports
- [ ] Email/SMS notifications
- [ ] Admin dashboard

## Liên hệ & Support

Dự án HousePal - Trợ lý quản lý nhà trọ/chung cư
