using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class Note
{
    [Key]
    public int Id { get; set; }

    public int HouseId { get; set; }

    public int CreatedByUserId { get; set; }

    [Required]
    [StringLength(100)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [StringLength(2000)]
    public string Content { get; set; } = string.Empty;

    [StringLength(20)]
    public string Type { get; set; } = "note"; // note, announcement, info

    [Required]
    public bool IsPinned { get; set; } = false;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual House? House { get; set; }
    public virtual User? CreatedByUser { get; set; }
}
