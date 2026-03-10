using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class Chore
{
    [Key]
    public int Id { get; set; }

    public int HouseId { get; set; }

    [Required]
    [StringLength(100)]
    public string Title { get; set; } = string.Empty;

    [StringLength(500)]
    public string? Description { get; set; }

    [Required]
    public int Points { get; set; } = 10; // Điểm thưởng khi hoàn thành

    [Required]
    [StringLength(20)]
    public string Frequency { get; set; } = "weekly"; // daily, weekly, monthly

    [Required]
    public int RotationOrderIndex { get; set; } = 0; // Vị trí trong danh sách xoay vòng

    [Required]
    public bool IsActive { get; set; } = true;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual House? House { get; set; }
    public virtual ICollection<ChoreAssignment> Assignments { get; set; } = new List<ChoreAssignment>();
    public virtual ICollection<ChoreCompletion> Completions { get; set; } = new List<ChoreCompletion>();
}
