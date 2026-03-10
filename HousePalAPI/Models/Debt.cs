using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class Debt
{
    [Key]
    public int Id { get; set; }

    public int HouseId { get; set; }

    public int DebtorUserId { get; set; } // Người nợ

    public int CreditorUserId { get; set; } // Người cho vay

    [Required]
    public decimal Amount { get; set; }

    [Required]
    public bool IsSettled { get; set; } = false;

    public DateTime? SettledAt { get; set; }

    [StringLength(500)]
    public string? Description { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual House? House { get; set; }
    public virtual User? DebtorUser { get; set; }
    public virtual User? CreditorUser { get; set; }
}
