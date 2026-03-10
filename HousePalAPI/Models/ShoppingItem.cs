using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class ShoppingItem
{
    [Key]
    public int Id { get; set; }

    public int HouseId { get; set; }

    public int AddedByUserId { get; set; }

    [Required]
    [StringLength(100)]
    public string ItemName { get; set; } = string.Empty;

    public decimal? EstimatedPrice { get; set; }

    [StringLength(20)]
    public string Status { get; set; } = "pending"; // pending, purchased, completed

    [StringLength(500)]
    public string? Notes { get; set; }

    [Required]
    public bool IsDone { get; set; } = false;

    public int? PurchasedByUserId { get; set; }

    public DateTime? PurchasedAt { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual House? House { get; set; }
    public virtual User? AddedByUser { get; set; }
    public virtual User? PurchasedByUser { get; set; }
}
