using Microsoft.EntityFrameworkCore;
using HousePalAPI.Models;

namespace HousePalAPI.Data;

public class HousePalDbContext : DbContext
{
    public HousePalDbContext(DbContextOptions<HousePalDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users { get; set; } = null!;
    public DbSet<House> Houses { get; set; } = null!;
    public DbSet<Chore> Chores { get; set; } = null!;
    public DbSet<ChoreAssignment> ChoreAssignments { get; set; } = null!;
    public DbSet<ChoreCompletion> ChoreCompletions { get; set; } = null!;
    public DbSet<Expense> Expenses { get; set; } = null!;
    public DbSet<ExpenseSplit> ExpenseSplits { get; set; } = null!;
    public DbSet<Debt> Debts { get; set; } = null!;
    public DbSet<Note> Notes { get; set; } = null!;
    public DbSet<ShoppingItem> ShoppingItems { get; set; } = null!;
    public DbSet<Notification> Notifications { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Configure User-House relationship
        modelBuilder.Entity<User>()
            .HasOne(u => u.House)
            .WithMany(h => h.Members)
            .HasForeignKey(u => u.HouseId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure Chore-House relationship
        modelBuilder.Entity<Chore>()
            .HasOne(c => c.House)
            .WithMany(h => h.Chores)
            .HasForeignKey(c => c.HouseId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure ChoreAssignment relationships
        modelBuilder.Entity<ChoreAssignment>()
            .HasOne(ca => ca.Chore)
            .WithMany(c => c.Assignments)
            .HasForeignKey(ca => ca.ChoreId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ChoreAssignment>()
            .HasOne(ca => ca.AssignedToUser)
            .WithMany(u => u.ChoreAssignments)
            .HasForeignKey(ca => ca.AssignedToUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure ChoreCompletion relationships
        modelBuilder.Entity<ChoreCompletion>()
            .HasOne(cc => cc.Chore)
            .WithMany(c => c.Completions)
            .HasForeignKey(cc => cc.ChoreId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ChoreCompletion>()
            .HasOne(cc => cc.CompletedByUser)
            .WithMany(u => u.ChoreCompletions)
            .HasForeignKey(cc => cc.CompletedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ChoreCompletion>()
            .HasOne(cc => cc.ChoreAssignment)
            .WithMany(ca => ca.Completions)
            .HasForeignKey(cc => cc.ChoreAssignmentId)
            .OnDelete(DeleteBehavior.Cascade);

        // Configure Expense relationships
        modelBuilder.Entity<Expense>()
            .HasOne(e => e.House)
            .WithMany(h => h.Expenses)
            .HasForeignKey(e => e.HouseId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Expense>()
            .HasOne(e => e.PaidByUser)
            .WithMany(u => u.Expenses)
            .HasForeignKey(e => e.PaidByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure ExpenseSplit relationships
        modelBuilder.Entity<ExpenseSplit>()
            .HasOne(es => es.Expense)
            .WithMany(e => e.Splits)
            .HasForeignKey(es => es.ExpenseId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ExpenseSplit>()
            .HasOne(es => es.User)
            .WithMany(u => u.ExpenseSplits)
            .HasForeignKey(es => es.UserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure Debt relationships
        modelBuilder.Entity<Debt>()
            .HasOne(d => d.House)
            .WithMany(h => h.Debts)
            .HasForeignKey(d => d.HouseId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Debt>()
            .HasOne(d => d.DebtorUser)
            .WithMany()
            .HasForeignKey(d => d.DebtorUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<Debt>()
            .HasOne(d => d.CreditorUser)
            .WithMany()
            .HasForeignKey(d => d.CreditorUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure Note relationships
        modelBuilder.Entity<Note>()
            .HasOne(n => n.House)
            .WithMany(h => h.Notes)
            .HasForeignKey(n => n.HouseId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<Note>()
            .HasOne(n => n.CreatedByUser)
            .WithMany()
            .HasForeignKey(n => n.CreatedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure ShoppingItem relationships
        modelBuilder.Entity<ShoppingItem>()
            .HasOne(si => si.House)
            .WithMany(h => h.ShoppingItems)
            .HasForeignKey(si => si.HouseId)
            .OnDelete(DeleteBehavior.Cascade);

        modelBuilder.Entity<ShoppingItem>()
            .HasOne(si => si.AddedByUser)
            .WithMany()
            .HasForeignKey(si => si.AddedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        modelBuilder.Entity<ShoppingItem>()
            .HasOne(si => si.PurchasedByUser)
            .WithMany()
            .HasForeignKey(si => si.PurchasedByUserId)
            .OnDelete(DeleteBehavior.Restrict);

        // Configure Notification relationships
        modelBuilder.Entity<Notification>()
            .HasOne(n => n.RecipientUser)
            .WithMany()
            .HasForeignKey(n => n.RecipientUserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
