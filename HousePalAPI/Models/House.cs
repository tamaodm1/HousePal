using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class House
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Description { get; set; }

    [Required]
    [StringLength(20)]
    public string JoinCode { get; set; } = string.Empty; // Mã code để join house

    public int MemberCount { get; set; } = 1;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual ICollection<User> Members { get; set; } = new List<User>();
    public virtual ICollection<Chore> Chores { get; set; } = new List<Chore>();
    public virtual ICollection<Expense> Expenses { get; set; } = new List<Expense>();
    public virtual ICollection<Note> Notes { get; set; } = new List<Note>();
    public virtual ICollection<ShoppingItem> ShoppingItems { get; set; } = new List<ShoppingItem>();
    public virtual ICollection<Debt> Debts { get; set; } = new List<Debt>();
}
