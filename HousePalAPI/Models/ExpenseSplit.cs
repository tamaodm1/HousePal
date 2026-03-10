using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class ExpenseSplit
{
    [Key]
    public int Id { get; set; }

    public int ExpenseId { get; set; }

    public int UserId { get; set; }

    [Required]
    public decimal Amount { get; set; } // Số tiền user cần trả

    [Required]
    public decimal Percentage { get; set; } = 0; // Phần trăm nếu là custom split

    [Required]
    public bool IsPaid { get; set; } = false;

    public DateTime? PaidAt { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual Expense? Expense { get; set; }
    public virtual User? User { get; set; }
}
