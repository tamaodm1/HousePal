-- HousePal Database Schema
-- SQL Server Script
-- Tạo database và các tables theo yêu cầu dự án

-- Tạo Database
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'HousePalDB')
BEGIN
    CREATE DATABASE HousePalDB;
END
GO

USE HousePalDB;
GO

-- 1. Houses Table - Ngôi nhà/Căn hộ chung
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Houses]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Houses] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [Name] NVARCHAR(100) NOT NULL,
        [Description] NVARCHAR(500),
        [JoinCode] NVARCHAR(20) NOT NULL UNIQUE,
        [MemberCount] INT DEFAULT 1,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE()
    );
END
GO

-- 2. Users Table - Thành viên nhà
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [Name] NVARCHAR(100) NOT NULL,
        [Email] NVARCHAR(100) NOT NULL,
        [PhoneNumber] NVARCHAR(20),
        [HouseId] INT NOT NULL,
        [IsAdmin] BIT DEFAULT 0,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([HouseId]) REFERENCES [Houses]([Id]) ON DELETE NO ACTION
    );
END
GO

-- 3. Chores Table - Công việc nhà
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Chores]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Chores] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT NOT NULL,
        [Title] NVARCHAR(100) NOT NULL,
        [Description] NVARCHAR(500),
        [Points] INT DEFAULT 10,
        [Frequency] NVARCHAR(20) DEFAULT 'weekly', -- daily, weekly, monthly
        [RotationOrderIndex] INT DEFAULT 0,
        [IsActive] BIT DEFAULT 1,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([HouseId]) REFERENCES [Houses]([Id]) ON DELETE CASCADE
    );
END
GO

-- 4. ChoreAssignments Table - Phân công việc nhà
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ChoreAssignments]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ChoreAssignments] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [ChoreId] INT NOT NULL,
        [AssignedToUserId] INT NOT NULL,
        [StartDate] DATETIME DEFAULT GETUTCDATE(),
        [EndDate] DATETIME,
        [IsCompleted] BIT DEFAULT 0,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([ChoreId]) REFERENCES [Chores]([Id]) ON DELETE CASCADE,
        FOREIGN KEY ([AssignedToUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION
    );
END
GO

-- 5. ChoreCompletions Table - Ghi nhận hoàn thành công việc
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ChoreCompletions]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ChoreCompletions] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [ChoreId] INT NOT NULL,
        [CompletedByUserId] INT NOT NULL,
        [ChoreAssignmentId] INT NOT NULL,
        [CompletedAt] DATETIME DEFAULT GETUTCDATE(),
        [Notes] NVARCHAR(500),
        [PointsEarned] INT DEFAULT 0,
        FOREIGN KEY ([ChoreId]) REFERENCES [Chores]([Id]) ON DELETE CASCADE,
        FOREIGN KEY ([CompletedByUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION,
        FOREIGN KEY ([ChoreAssignmentId]) REFERENCES [ChoreAssignments]([Id]) ON DELETE CASCADE
    );
END
GO

-- 6. Expenses Table - Chi tiêu chung
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Expenses]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Expenses] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT NOT NULL,
        [PaidByUserId] INT NOT NULL,
        [Description] NVARCHAR(100) NOT NULL,
        [Amount] DECIMAL(10,2) NOT NULL,
        [Category] NVARCHAR(20) DEFAULT 'other', -- utilities, groceries, rent, other
        [SplitType] NVARCHAR(20) DEFAULT 'equal', -- equal, custom, people
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([HouseId]) REFERENCES [Houses]([Id]) ON DELETE CASCADE,
        FOREIGN KEY ([PaidByUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION
    );
END
GO

-- 7. ExpenseSplits Table - Chi tiết chia chi tiêu
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ExpenseSplits]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ExpenseSplits] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [ExpenseId] INT NOT NULL,
        [UserId] INT NOT NULL,
        [Amount] DECIMAL(10,2) NOT NULL,
        [Percentage] DECIMAL(5,2) DEFAULT 0,
        [IsPaid] BIT DEFAULT 0,
        [PaidAt] DATETIME,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([ExpenseId]) REFERENCES [Expenses]([Id]) ON DELETE CASCADE,
        FOREIGN KEY ([UserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION
    );
END
GO

-- 8. Debts Table - Bảng "Ai nợ Ai"
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Debts]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Debts] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT NOT NULL,
        [DebtorUserId] INT NOT NULL, -- Người nợ
        [CreditorUserId] INT NOT NULL, -- Người cho vay
        [Amount] DECIMAL(10,2) NOT NULL,
        [IsSettled] BIT DEFAULT 0,
        [SettledAt] DATETIME,
        [Description] NVARCHAR(500),
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([HouseId]) REFERENCES [Houses]([Id]) ON DELETE CASCADE,
        FOREIGN KEY ([DebtorUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION,
        FOREIGN KEY ([CreditorUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION
    );
END
GO

-- 9. Notes Table - Ghi chú chung
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Notes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Notes] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT NOT NULL,
        [CreatedByUserId] INT NOT NULL,
        [Title] NVARCHAR(100) NOT NULL,
        [Content] NVARCHAR(2000) NOT NULL,
        [Type] NVARCHAR(20) DEFAULT 'note', -- note, announcement, info
        [IsPinned] BIT DEFAULT 0,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([HouseId]) REFERENCES [Houses]([Id]) ON DELETE CASCADE,
        FOREIGN KEY ([CreatedByUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION
    );
END
GO

-- 10. ShoppingItems Table - Danh sách mua sắm
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ShoppingItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ShoppingItems] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT NOT NULL,
        [AddedByUserId] INT NOT NULL,
        [ItemName] NVARCHAR(100) NOT NULL,
        [EstimatedPrice] DECIMAL(10,2),
        [Status] NVARCHAR(20) DEFAULT 'pending', -- pending, purchased, completed
        [Notes] NVARCHAR(500),
        [IsDone] BIT DEFAULT 0,
        [PurchasedByUserId] INT,
        [PurchasedAt] DATETIME,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([HouseId]) REFERENCES [Houses]([Id]) ON DELETE CASCADE,
        FOREIGN KEY ([AddedByUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION,
        FOREIGN KEY ([PurchasedByUserId]) REFERENCES [Users]([Id]) ON DELETE NO ACTION
    );
END
GO

-- 11. Notifications Table - Thông báo
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Notifications]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Notifications] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [RecipientUserId] INT NOT NULL,
        [Title] NVARCHAR(100) NOT NULL,
        [Message] NVARCHAR(500) NOT NULL,
        [Type] NVARCHAR(20) DEFAULT 'info', -- chore, expense, note, info
        [IsRead] BIT DEFAULT 0,
        [ReadAt] DATETIME,
        [RelatedLink] NVARCHAR(200),
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        FOREIGN KEY ([RecipientUserId]) REFERENCES [Users]([Id]) ON DELETE CASCADE
    );
END
GO

-- Tạo Indexes để tối ưu performance
CREATE INDEX IX_Users_HouseId ON [Users]([HouseId]);
CREATE INDEX IX_Chores_HouseId ON [Chores]([HouseId]);
CREATE INDEX IX_ChoreAssignments_ChoreId ON [ChoreAssignments]([ChoreId]);
CREATE INDEX IX_ChoreAssignments_AssignedToUserId ON [ChoreAssignments]([AssignedToUserId]);
CREATE INDEX IX_ChoreCompletions_ChoreId ON [ChoreCompletions]([ChoreId]);
CREATE INDEX IX_ChoreCompletions_CompletedByUserId ON [ChoreCompletions]([CompletedByUserId]);
CREATE INDEX IX_Expenses_HouseId ON [Expenses]([HouseId]);
CREATE INDEX IX_Expenses_PaidByUserId ON [Expenses]([PaidByUserId]);
CREATE INDEX IX_ExpenseSplits_ExpenseId ON [ExpenseSplits]([ExpenseId]);
CREATE INDEX IX_ExpenseSplits_UserId ON [ExpenseSplits]([UserId]);
CREATE INDEX IX_Debts_HouseId ON [Debts]([HouseId]);
CREATE INDEX IX_Debts_DebtorUserId ON [Debts]([DebtorUserId]);
CREATE INDEX IX_Debts_CreditorUserId ON [Debts]([CreditorUserId]);
CREATE INDEX IX_Notes_HouseId ON [Notes]([HouseId]);
CREATE INDEX IX_Notes_CreatedByUserId ON [Notes]([CreatedByUserId]);
CREATE INDEX IX_ShoppingItems_HouseId ON [ShoppingItems]([HouseId]);
CREATE INDEX IX_ShoppingItems_AddedByUserId ON [ShoppingItems]([AddedByUserId]);
CREATE INDEX IX_Notifications_RecipientUserId ON [Notifications]([RecipientUserId]);

-- Lệnh để xem các tables
-- SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo';

-- Lệnh để xóa database (nếu cần restart)
-- DROP DATABASE HousePalDB;
