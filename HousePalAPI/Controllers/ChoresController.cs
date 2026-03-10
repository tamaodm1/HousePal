using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HousePalAPI.Data;
using HousePalAPI.Models;

namespace HousePalAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ChoresController : ControllerBase
{
    private readonly HousePalDbContext _context;

    public ChoresController(HousePalDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Chore>>> GetChores()
    {
        return await _context.Chores.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Chore>> GetChore(int id)
    {
        var chore = await _context.Chores.FindAsync(id);
        if (chore == null)
            return NotFound();
        return chore;
    }

    [HttpPost]
    public async Task<ActionResult<Chore>> CreateChore(Chore chore)
    {
        _context.Chores.Add(chore);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetChore), new { id = chore.Id }, chore);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateChore(int id, Chore chore)
    {
        if (id != chore.Id)
            return BadRequest();

        _context.Entry(chore).State = EntityState.Modified;
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ChoreExists(id))
                return NotFound();
            throw;
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteChore(int id)
    {
        var chore = await _context.Chores.FindAsync(id);
        if (chore == null)
            return NotFound();

        _context.Chores.Remove(chore);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private bool ChoreExists(int id)
    {
        return _context.Chores.Any(e => e.Id == id);
    }

    // Assign chore to user
    [HttpPost("{id}/assign")]
    public async Task<ActionResult<ChoreAssignment>> AssignChore(int id, [FromBody] AssignChoreRequest request)
    {
        var chore = await _context.Chores.FindAsync(id);
        if (chore == null)
            return NotFound("Chore not found");

        var user = await _context.Users.FindAsync(request.UserId);
        if (user == null)
            return NotFound("User not found");

        var assignment = new ChoreAssignment
        {
            ChoreId = id,
            AssignedToUserId = request.UserId,
            StartDate = DateTime.UtcNow,
            IsCompleted = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.ChoreAssignments.Add(assignment);
        await _context.SaveChangesAsync();

        return CreatedAtAction(nameof(GetChore), new { id = chore.Id }, assignment);
    }

    // Complete chore assignment
    [HttpPost("{id}/complete")]
    public async Task<ActionResult> CompleteChore(int id, [FromBody] CompleteChoreRequest request)
    {
        var assignment = await _context.ChoreAssignments
            .Include(a => a.Chore)
            .FirstOrDefaultAsync(a => a.ChoreId == id && a.AssignedToUserId == request.UserId && !a.IsCompleted);

        if (assignment == null)
            return NotFound("Assignment not found or already completed");

        // Only assigned user can complete
        if (assignment.AssignedToUserId != request.UserId)
            return Forbid("Only assigned user can complete this chore");

        assignment.IsCompleted = true;
        assignment.UpdatedAt = DateTime.UtcNow;

        // Add completion record
        var completion = new ChoreCompletion
        {
            ChoreId = id,
            ChoreAssignmentId = assignment.Id,
            CompletedByUserId = request.UserId,
            CompletedAt = DateTime.UtcNow,
            PointsEarned = assignment.Chore?.Points ?? 0
        };
        _context.ChoreCompletions.Add(completion);

        // Update user points
        var user = await _context.Users.FindAsync(request.UserId);
        if (user != null)
        {
            user.ChorePoints += assignment.Chore?.Points ?? 0;
            user.UpdatedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return Ok(new { message = "Chore completed!", points = assignment.Chore?.Points ?? 0 });
    }

    // Get assignments for a chore
    [HttpGet("{id}/assignments")]
    public async Task<ActionResult<IEnumerable<ChoreAssignment>>> GetChoreAssignments(int id)
    {
        var assignments = await _context.ChoreAssignments
            .Include(a => a.AssignedToUser)
            .Where(a => a.ChoreId == id)
            .ToListAsync();
        return Ok(assignments);
    }

    // Get my assigned chores
    [HttpGet("my/{userId}")]
    public async Task<ActionResult<IEnumerable<object>>> GetMyChores(int userId)
    {
        var assignments = await _context.ChoreAssignments
            .Include(a => a.Chore)
            .Include(a => a.AssignedToUser)
            .Where(a => a.AssignedToUserId == userId && !a.IsCompleted)
            .Select(a => new {
                a.Id,
                a.ChoreId,
                a.AssignedToUserId,
                AssignedToUserName = a.AssignedToUser != null ? a.AssignedToUser.Name : "",
                a.StartDate,
                a.IsCompleted,
                Chore = a.Chore
            })
            .ToListAsync();
        return Ok(assignments);
    }
}

public class AssignChoreRequest
{
    public int UserId { get; set; }
}

public class CompleteChoreRequest
{
    public int UserId { get; set; }
}
