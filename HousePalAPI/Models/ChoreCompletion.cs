using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class ChoreCompletion
{
    [Key]
    public int Id { get; set; }

    public int ChoreId { get; set; }

    public int CompletedByUserId { get; set; }

    public int ChoreAssignmentId { get; set; }

    [Required]
    public DateTime CompletedAt { get; set; } = DateTime.UtcNow;

    [StringLength(500)]
    public string? Notes { get; set; }

    [Required]
    public int PointsEarned { get; set; } = 0;

    // Navigation properties
    public virtual Chore? Chore { get; set; }
    public virtual User? CompletedByUser { get; set; }
    public virtual ChoreAssignment? ChoreAssignment { get; set; }
}
