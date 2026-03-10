using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HousePalAPI.Data;
using HousePalAPI.Models;

namespace HousePalAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly HousePalDbContext _context;

    public UsersController(HousePalDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<User>>> GetUsers()
    {
        return await _context.Users.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<User>> GetUser(int id)
    {
        var user = await _context.Users.FindAsync(id);
        if (user == null)
            return NotFound();
        return user;
    }

    [HttpPost]
    public async Task<ActionResult<object>> CreateUser([FromBody] User user)
    {
        // Validate required fields
        if (string.IsNullOrWhiteSpace(user?.Name))
            return BadRequest(new { error = "Name is required" });
        
        if (string.IsNullOrWhiteSpace(user?.Email))
            return BadRequest(new { error = "Email is required" });

        try
        {
            // Nếu chưa có House, tạo House mới
            if (user.HouseId == 0)
            {
                var newHouse = new House
                {
                    Name = $"House of {user.Name}",
                    Description = $"Welcome to {user.Name}'s house!",
                    JoinCode = Guid.NewGuid().ToString().Substring(0, 8).ToUpper(),
                    MemberCount = 1,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                _context.Houses.Add(newHouse);
                await _context.SaveChangesAsync();
                user.HouseId = newHouse.Id;
            }

            user.CreatedAt = DateTime.UtcNow;
            user.UpdatedAt = DateTime.UtcNow;
            
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            
            // Return lightly (không include relationships)
            return Ok(new { id = user.Id, name = user.Name, email = user.Email, houseId = user.HouseId });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<object>> UpdateUser(int id, [FromBody] User user)
    {
        try
        {
            var existingUser = await _context.Users.FindAsync(id);
            if (existingUser == null)
                return NotFound(new { error = "User not found" });

            // Update fields
            existingUser.Name = user.Name ?? existingUser.Name;
            existingUser.Email = user.Email ?? existingUser.Email;
            existingUser.PhoneNumber = user.PhoneNumber ?? existingUser.PhoneNumber;
            existingUser.HouseId = user.HouseId > 0 ? user.HouseId : existingUser.HouseId;
            existingUser.IsAdmin = user.IsAdmin;
            existingUser.UpdatedAt = DateTime.UtcNow;

            _context.Users.Update(existingUser);
            await _context.SaveChangesAsync();

            return Ok(new { id = existingUser.Id, name = existingUser.Name, email = existingUser.Email, houseId = existingUser.HouseId });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }
}
