-- HousePal Database Schema (Simplified)
-- SQL Server

IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'HousePalDB')
BEGIN
    CREATE DATABASE HousePalDB;
END
GO

USE HousePalDB;
GO

-- 1. Houses Table
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

-- 2. Users Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [Name] NVARCHAR(100) NOT NULL,
        [Email] NVARCHAR(100) NOT NULL,
        [PhoneNumber] NVARCHAR(20),
        [HouseId] INT,
        [IsAdmin] BIT DEFAULT 0,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME DEFAULT GETUTCDATE()
    );
END
GO

-- 3. Chores Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Chores]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Chores] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT,
        [Title] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(500),
        [Frequency] NVARCHAR(50),
        [Points] INT DEFAULT 0,
        [AssignedTo] INT,
        [IsCompleted] BIT DEFAULT 0,
        [DueDate] DATETIME,
        [CompletedDate] DATETIME,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE()
    );
END
GO

-- 4. Expenses Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Expenses]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Expenses] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT,
        [Title] NVARCHAR(200) NOT NULL,
        [Amount] DECIMAL(10,2),
        [PaidBy] INT,
        [Date] DATETIME,
        [Category] NVARCHAR(100),
        [Note] NVARCHAR(500),
        [CreatedAt] DATETIME DEFAULT GETUTCDATE()
    );
END
GO

-- 5. Notes (Bulletin) Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Notes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[Notes] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT,
        [Title] NVARCHAR(200),
        [Content] NVARCHAR(MAX),
        [CreatedBy] INT,
        [IsPinned] BIT DEFAULT 0,
        [CreatedAt] DATETIME DEFAULT GETUTCDATE()
    );
END
GO

-- 6. Shopping Items Table
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ShoppingItems]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[ShoppingItems] (
        [Id] INT PRIMARY KEY IDENTITY(1,1),
        [HouseId] INT,
        [Name] NVARCHAR(200) NOT NULL,
        [IsPurchased] BIT DEFAULT 0,
        [AddedBy] INT,
        [PurchasedBy] INT,
        [AddedAt] DATETIME DEFAULT GETUTCDATE(),
        [PurchasedAt] DATETIME
    );
END
GO

PRINT 'Database setup complete!';
