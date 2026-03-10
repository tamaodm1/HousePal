using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class Notification
{
    [Key]
    public int Id { get; set; }

    public int RecipientUserId { get; set; }

    [Required]
    [StringLength(100)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [StringLength(500)]
    public string Message { get; set; } = string.Empty;

    [StringLength(20)]
    public string Type { get; set; } = "info"; // chore, expense, note, info

    [Required]
    public bool IsRead { get; set; } = false;

    public DateTime? ReadAt { get; set; }

    [StringLength(200)]
    public string? RelatedLink { get; set; }

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual User? RecipientUser { get; set; }
}
