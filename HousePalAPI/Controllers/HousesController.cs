using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HousePalAPI.Data;
using HousePalAPI.Models;

namespace HousePalAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HousesController : ControllerBase
{
    private readonly HousePalDbContext _context;

    public HousesController(HousePalDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<House>>> GetHouses()
    {
        return await _context.Houses.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<House>> GetHouse(int id)
    {
        var house = await _context.Houses.FindAsync(id);
        if (house == null)
            return NotFound();
        return house;
    }

    [HttpPost]
    public async Task<ActionResult<House>> CreateHouse([FromBody] House house)
    {
        if (string.IsNullOrWhiteSpace(house?.Name))
            return BadRequest(new { error = "Name is required" });

        try
        {
            house.CreatedAt = DateTime.UtcNow;
            house.UpdatedAt = DateTime.UtcNow;
            
            _context.Houses.Add(house);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetHouse), new { id = house.Id }, house);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateHouse(int id, House house)
    {
        if (id != house.Id)
            return BadRequest();

        _context.Entry(house).State = EntityState.Modified;
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!HouseExists(id))
                return NotFound();
            throw;
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteHouse(int id)
    {
        var house = await _context.Houses.FindAsync(id);
        if (house == null)
            return NotFound();

        _context.Houses.Remove(house);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private bool HouseExists(int id)
    {
        return _context.Houses.Any(e => e.Id == id);
    }
}
