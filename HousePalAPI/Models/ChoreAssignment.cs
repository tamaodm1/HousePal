using System.ComponentModel.DataAnnotations;

namespace HousePalAPI.Models;

public class ChoreAssignment
{
    [Key]
    public int Id { get; set; }

    public int ChoreId { get; set; }

    public int AssignedToUserId { get; set; }

    [Required]
    public DateTime StartDate { get; set; } = DateTime.UtcNow;

    public DateTime? EndDate { get; set; }

    [Required]
    public bool IsCompleted { get; set; } = false;

    [Required]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public virtual Chore? Chore { get; set; }
    public virtual User? AssignedToUser { get; set; }
    public virtual ICollection<ChoreCompletion> Completions { get; set; } = new List<ChoreCompletion>();
}
