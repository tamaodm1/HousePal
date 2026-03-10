using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class Expense
{
    [Key]
    public int Id { get; set; }

    public int HouseId { get; set; }

    public int PaidByUserId { get; set; }

    [Required]
    [StringLength(100)]
    public string Description { get; set; } = string.Empty;

    [Required]
    public decimal Amount { get; set; }

    [StringLength(20)]
    public string Category { get; set; } = "other"; // utilities, groceries, rent, other

    [StringLength(20)]
    public string SplitType { get; set; } = "equal"; // equal, custom, people

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual House? House { get; set; }
    public virtual User? PaidByUser { get; set; }
    public virtual ICollection<ExpenseSplit> Splits { get; set; } = new List<ExpenseSplit>();
}
