using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HousePalAPI.Data;
using HousePalAPI.Models;

namespace HousePalAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ShoppingItemsController : ControllerBase
{
    private readonly HousePalDbContext _context;

    public ShoppingItemsController(HousePalDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ShoppingItem>>> GetShoppingItems()
    {
        return await _context.ShoppingItems.ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ShoppingItem>> GetShoppingItem(int id)
    {
        var item = await _context.ShoppingItems.FindAsync(id);
        if (item == null)
            return NotFound();
        return item;
    }

    [HttpPost]
    public async Task<ActionResult<ShoppingItem>> CreateShoppingItem(ShoppingItem item)
    {
        _context.ShoppingItems.Add(item);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(GetShoppingItem), new { id = item.Id }, item);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateShoppingItem(int id, ShoppingItem item)
    {
        if (id != item.Id)
            return BadRequest();

        _context.Entry(item).State = EntityState.Modified;
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ShoppingItemExists(id))
                return NotFound();
            throw;
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteShoppingItem(int id)
    {
        var item = await _context.ShoppingItems.FindAsync(id);
        if (item == null)
            return NotFound();

        _context.ShoppingItems.Remove(item);
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private bool ShoppingItemExists(int id)
    {
        return _context.ShoppingItems.Any(e => e.Id == id);
    }
}
