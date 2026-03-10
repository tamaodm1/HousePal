using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class User
{
    [Key]
    public int Id { get; set; }

    [Required]
    [StringLength(100)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [StringLength(100)]
    public string Email { get; set; } = string.Empty;

    [StringLength(20)]
    public string? PhoneNumber { get; set; }

    public int? HouseId { get; set; }

    public int ChorePoints { get; set; } = 0;

    [Required]
    public bool IsAdmin { get; set; } = false;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual House? House { get; set; }
    public virtual ICollection<ChoreAssignment> ChoreAssignments { get; set; } = new List<ChoreAssignment>();
    public virtual ICollection<ChoreCompletion> ChoreCompletions { get; set; } = new List<ChoreCompletion>();
    public virtual ICollection<Expense> Expenses { get; set; } = new List<Expense>();
    public virtual ICollection<ExpenseSplit> ExpenseSplits { get; set; } = new List<ExpenseSplit>();
}
