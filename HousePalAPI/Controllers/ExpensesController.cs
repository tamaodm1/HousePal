using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using HousePalAPI.Data;
using HousePalAPI.Models;

namespace HousePalAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ExpensesController : ControllerBase
{
    private readonly HousePalDbContext _context;

    public ExpensesController(HousePalDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<Expense>>> GetExpenses([FromQuery] int? houseId)
    {
        var query = _context.Expenses.Include(e => e.PaidByUser).AsQueryable();
        if (houseId.HasValue)
            query = query.Where(e => e.HouseId == houseId.Value);
        return await query.OrderByDescending(e => e.CreatedAt).ToListAsync();
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<Expense>> GetExpense(int id)
    {
        var expense = await _context.Expenses
            .Include(e => e.PaidByUser)
            .Include(e => e.Splits)
            .ThenInclude(s => s.User)
            .FirstOrDefaultAsync(e => e.Id == id);
        if (expense == null)
            return NotFound();
        return expense;
    }

    // Tạo chi tiêu mới với phân chia
    [HttpPost]
    public async Task<ActionResult<Expense>> CreateExpense([FromBody] CreateExpenseRequest request)
    {
        // Tạo expense
        var expense = new Expense
        {
            HouseId = request.HouseId,
            PaidByUserId = request.PaidByUserId,
            Description = request.Description,
            Amount = request.Amount,
            Category = request.Category ?? "other",
            SplitType = request.SplitType ?? "equal",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Expenses.Add(expense);
        await _context.SaveChangesAsync();

        // Lấy danh sách thành viên trong nhà
        var members = await _context.Users
            .Where(u => u.HouseId == request.HouseId)
            .ToListAsync();

        // Tạo splits dựa trên loại chia
        var splits = new List<ExpenseSplit>();

        if (request.SplitType == "equal")
        {
            // Chia đều cho tất cả thành viên
            var splitAmount = request.Amount / members.Count;
            var percentage = 100.0m / members.Count;

            foreach (var member in members)
            {
                splits.Add(new ExpenseSplit
                {
                    ExpenseId = expense.Id,
                    UserId = member.Id,
                    Amount = splitAmount,
                    Percentage = percentage,
                    IsPaid = member.Id == request.PaidByUserId, // Người trả đã "trả" phần của họ
                    PaidAt = member.Id == request.PaidByUserId ? DateTime.UtcNow : null,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }
        else if (request.SplitType == "custom" && request.CustomSplits != null)
        {
            // Chia theo tỷ lệ tùy chỉnh
            foreach (var customSplit in request.CustomSplits)
            {
                var amount = request.Amount * (customSplit.Percentage / 100);
                splits.Add(new ExpenseSplit
                {
                    ExpenseId = expense.Id,
                    UserId = customSplit.UserId,
                    Amount = amount,
                    Percentage = customSplit.Percentage,
                    IsPaid = customSplit.UserId == request.PaidByUserId,
                    PaidAt = customSplit.UserId == request.PaidByUserId ? DateTime.UtcNow : null,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }
        else if (request.SplitType == "people" && request.SelectedUserIds != null)
        {
            // Chỉ chia cho những người được chọn
            var selectedCount = request.SelectedUserIds.Count;
            var splitAmount = request.Amount / selectedCount;
            var percentage = 100.0m / selectedCount;

            foreach (var userId in request.SelectedUserIds)
            {
                splits.Add(new ExpenseSplit
                {
                    ExpenseId = expense.Id,
                    UserId = userId,
                    Amount = splitAmount,
                    Percentage = percentage,
                    IsPaid = userId == request.PaidByUserId,
                    PaidAt = userId == request.PaidByUserId ? DateTime.UtcNow : null,
                    CreatedAt = DateTime.UtcNow
                });
            }
        }

        _context.ExpenseSplits.AddRange(splits);
        await _context.SaveChangesAsync();

        // Cập nhật bảng nợ
        await UpdateDebtsForHouse(request.HouseId);

        return CreatedAtAction(nameof(GetExpense), new { id = expense.Id }, expense);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateExpense(int id, Expense expense)
    {
        if (id != expense.Id)
            return BadRequest();

        expense.UpdatedAt = DateTime.UtcNow;
        _context.Entry(expense).State = EntityState.Modified;
        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!ExpenseExists(id))
                return NotFound();
            throw;
        }
        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteExpense(int id)
    {
        var expense = await _context.Expenses.FindAsync(id);
        if (expense == null)
            return NotFound();

        var houseId = expense.HouseId;
        _context.Expenses.Remove(expense);
        await _context.SaveChangesAsync();

        // Cập nhật lại bảng nợ sau khi xóa
        await UpdateDebtsForHouse(houseId);

        return NoContent();
    }

    // ========== BALANCE & DEBT APIs ==========

    /// <summary>
    /// Lấy bảng cân đối nợ của một house - "Ai nợ Ai"
    /// </summary>
    [HttpGet("balance/{houseId}")]
    public async Task<ActionResult<BalanceResponse>> GetHouseBalance(int houseId)
    {
        var house = await _context.Houses.FindAsync(houseId);
        if (house == null)
            return NotFound("House not found");

        // Lấy tất cả nợ chưa thanh toán của house
        var debts = await _context.Debts
            .Include(d => d.DebtorUser)
            .Include(d => d.CreditorUser)
            .Where(d => d.HouseId == houseId && !d.IsSettled)
            .ToListAsync();

        var members = await _context.Users
            .Where(u => u.HouseId == houseId)
            .Select(u => new UserBalanceInfo
            {
                UserId = u.Id,
                UserName = u.Name,
                Email = u.Email
            })
            .ToListAsync();

        // Tính tổng nợ và được nợ cho mỗi user
        foreach (var member in members)
        {
            member.TotalOwes = debts.Where(d => d.DebtorUserId == member.UserId).Sum(d => d.Amount);
            member.TotalOwed = debts.Where(d => d.CreditorUserId == member.UserId).Sum(d => d.Amount);
            member.NetBalance = member.TotalOwed - member.TotalOwes;
        }

        // Tạo danh sách chi tiết nợ
        var debtDetails = debts.Select(d => new DebtDetail
        {
            Id = d.Id,
            DebtorUserId = d.DebtorUserId,
            DebtorName = d.DebtorUser?.Name ?? "",
            CreditorUserId = d.CreditorUserId,
            CreditorName = d.CreditorUser?.Name ?? "",
            Amount = d.Amount,
            Description = d.Description,
            CreatedAt = d.CreatedAt
        }).ToList();

        // Tạo gợi ý thanh toán tối giản
        var simplifiedPayments = SimplifyDebts(debts);

        return Ok(new BalanceResponse
        {
            HouseId = houseId,
            HouseName = house.Name,
            Members = members,
            Debts = debtDetails,
            SimplifiedPayments = simplifiedPayments,
            TotalUnsettledAmount = debts.Sum(d => d.Amount)
        });
    }

    /// <summary>
    /// Lấy balance của một user cụ thể
    /// </summary>
    [HttpGet("balance/user/{userId}")]
    public async Task<ActionResult<UserBalanceResponse>> GetUserBalance(int userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null)
            return NotFound("User not found");

        if (!user.HouseId.HasValue)
            return BadRequest("User is not in any house");

        // Nợ user phải trả
        var debtsOwing = await _context.Debts
            .Include(d => d.CreditorUser)
            .Where(d => d.DebtorUserId == userId && !d.IsSettled)
            .Select(d => new DebtDetail
            {
                Id = d.Id,
                DebtorUserId = d.DebtorUserId,
                DebtorName = user.Name,
                CreditorUserId = d.CreditorUserId,
                CreditorName = d.CreditorUser!.Name,
                Amount = d.Amount,
                Description = d.Description,
                CreatedAt = d.CreatedAt
            })
            .ToListAsync();

        // Nợ người khác phải trả cho user
        var debtsOwed = await _context.Debts
            .Include(d => d.DebtorUser)
            .Where(d => d.CreditorUserId == userId && !d.IsSettled)
            .Select(d => new DebtDetail
            {
                Id = d.Id,
                DebtorUserId = d.DebtorUserId,
                DebtorName = d.DebtorUser!.Name,
                CreditorUserId = d.CreditorUserId,
                CreditorName = user.Name,
                Amount = d.Amount,
                Description = d.Description,
                CreatedAt = d.CreatedAt
            })
            .ToListAsync();

        return Ok(new UserBalanceResponse
        {
            UserId = userId,
            UserName = user.Name,
            TotalOwes = debtsOwing.Sum(d => d.Amount),
            TotalOwed = debtsOwed.Sum(d => d.Amount),
            NetBalance = debtsOwed.Sum(d => d.Amount) - debtsOwing.Sum(d => d.Amount),
            DebtsOwing = debtsOwing,
            DebtsOwed = debtsOwed
        });
    }

    /// <summary>
    /// Thanh toán nợ (settle debt)
    /// </summary>
    [HttpPost("settle")]
    public async Task<ActionResult> SettleDebt([FromBody] SettleDebtRequest request)
    {
        var debt = await _context.Debts.FindAsync(request.DebtId);
        if (debt == null)
            return NotFound("Debt not found");

        if (debt.IsSettled)
            return BadRequest("Debt is already settled");

        // Xác nhận thanh toán
        debt.IsSettled = true;
        debt.SettledAt = DateTime.UtcNow;
        debt.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { message = "Debt settled successfully", debtId = debt.Id });
    }

    /// <summary>
    /// Thanh toán một phần nợ
    /// </summary>
    [HttpPost("settle-partial")]
    public async Task<ActionResult> SettlePartialDebt([FromBody] SettlePartialRequest request)
    {
        var debt = await _context.Debts.FindAsync(request.DebtId);
        if (debt == null)
            return NotFound("Debt not found");

        if (debt.IsSettled)
            return BadRequest("Debt is already settled");

        if (request.Amount >= debt.Amount)
        {
            // Thanh toán toàn bộ
            debt.IsSettled = true;
            debt.SettledAt = DateTime.UtcNow;
        }
        else
        {
            // Giảm số nợ
            debt.Amount -= request.Amount;
        }
        debt.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();

        return Ok(new { 
            message = debt.IsSettled ? "Debt fully settled" : "Partial payment recorded",
            remainingAmount = debt.IsSettled ? 0 : debt.Amount
        });
    }

    // ========== PRIVATE HELPER METHODS ==========

    /// <summary>
    /// Thuật toán tối giản nợ - Minimizes number of transactions
    /// </summary>
    private List<SimplifiedPayment> SimplifyDebts(List<Debt> debts)
    {
        if (!debts.Any()) return new List<SimplifiedPayment>();

        // Tính net balance cho mỗi user
        var balances = new Dictionary<int, decimal>();
        var userNames = new Dictionary<int, string>();

        foreach (var debt in debts)
        {
            // Debtor nợ tiền (balance âm)
            if (!balances.ContainsKey(debt.DebtorUserId))
                balances[debt.DebtorUserId] = 0;
            balances[debt.DebtorUserId] -= debt.Amount;

            // Creditor được nợ (balance dương)
            if (!balances.ContainsKey(debt.CreditorUserId))
                balances[debt.CreditorUserId] = 0;
            balances[debt.CreditorUserId] += debt.Amount;

            // Lưu tên
            if (debt.DebtorUser != null)
                userNames[debt.DebtorUserId] = debt.DebtorUser.Name;
            if (debt.CreditorUser != null)
                userNames[debt.CreditorUserId] = debt.CreditorUser.Name;
        }

        // Tách thành 2 nhóm: người nợ (balance < 0) và người được nợ (balance > 0)
        var debtors = balances.Where(b => b.Value < 0)
            .OrderBy(b => b.Value) // Sắp xếp theo nợ nhiều nhất trước
            .Select(b => new { UserId = b.Key, Amount = -b.Value }) // Chuyển thành số dương
            .ToList();

        var creditors = balances.Where(b => b.Value > 0)
            .OrderByDescending(b => b.Value) // Sắp xếp theo được nợ nhiều nhất trước
            .Select(b => new { UserId = b.Key, Amount = b.Value })
            .ToList();

        var simplifiedPayments = new List<SimplifiedPayment>();

        // Greedy algorithm: match debtors with creditors
        int i = 0, j = 0;
        var debtorAmounts = debtors.Select(d => d.Amount).ToList();
        var creditorAmounts = creditors.Select(c => c.Amount).ToList();

        while (i < debtors.Count && j < creditors.Count)
        {
            var amount = Math.Min(debtorAmounts[i], creditorAmounts[j]);

            if (amount > 0)
            {
                simplifiedPayments.Add(new SimplifiedPayment
                {
                    FromUserId = debtors[i].UserId,
                    FromUserName = userNames.GetValueOrDefault(debtors[i].UserId, $"User {debtors[i].UserId}"),
                    ToUserId = creditors[j].UserId,
                    ToUserName = userNames.GetValueOrDefault(creditors[j].UserId, $"User {creditors[j].UserId}"),
                    Amount = amount
                });
            }

            debtorAmounts[i] -= amount;
            creditorAmounts[j] -= amount;

            if (debtorAmounts[i] == 0) i++;
            if (creditorAmounts[j] == 0) j++;
        }

        return simplifiedPayments;
    }

    /// <summary>
    /// Cập nhật bảng nợ dựa trên tất cả expense splits chưa thanh toán
    /// </summary>
    private async Task UpdateDebtsForHouse(int houseId)
    {
        // Xóa tất cả nợ chưa settle của house
        var existingDebts = await _context.Debts
            .Where(d => d.HouseId == houseId && !d.IsSettled)
            .ToListAsync();
        _context.Debts.RemoveRange(existingDebts);

        // Lấy tất cả expenses và splits của house
        var expenses = await _context.Expenses
            .Include(e => e.Splits)
            .Where(e => e.HouseId == houseId)
            .ToListAsync();

        // Tính net balance giữa các cặp user
        var netDebts = new Dictionary<(int debtor, int creditor), decimal>();

        foreach (var expense in expenses)
        {
            var paidByUserId = expense.PaidByUserId;

            foreach (var split in expense.Splits)
            {
                // Nếu người này chưa trả phần của họ và không phải người đã trả expense
                if (!split.IsPaid && split.UserId != paidByUserId)
                {
                    var key = (split.UserId, paidByUserId);
                    if (!netDebts.ContainsKey(key))
                        netDebts[key] = 0;
                    netDebts[key] += split.Amount;
                }
            }
        }

        // Tối giản nợ giữa các cặp (A nợ B và B nợ A -> chỉ giữ lại net)
        var simplifiedDebts = new Dictionary<(int debtor, int creditor), decimal>();

        foreach (var debt in netDebts)
        {
            var reverseKey = (debt.Key.creditor, debt.Key.debtor);
            
            if (netDebts.ContainsKey(reverseKey))
            {
                // Có nợ 2 chiều, tính net
                var netAmount = debt.Value - netDebts[reverseKey];
                if (netAmount > 0)
                {
                    simplifiedDebts[debt.Key] = netAmount;
                }
            }
            else if (!simplifiedDebts.ContainsKey(reverseKey))
            {
                simplifiedDebts[debt.Key] = debt.Value;
            }
        }

        // Tạo debt records mới
        foreach (var debt in simplifiedDebts)
        {
            if (debt.Value > 0)
            {
                _context.Debts.Add(new Debt
                {
                    HouseId = houseId,
                    DebtorUserId = debt.Key.debtor,
                    CreditorUserId = debt.Key.creditor,
                    Amount = debt.Value,
                    IsSettled = false,
                    Description = "Auto-calculated from expenses",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });
            }
        }

        await _context.SaveChangesAsync();
    }

    private bool ExpenseExists(int id)
    {
        return _context.Expenses.Any(e => e.Id == id);
    }
}

// ========== REQUEST/RESPONSE DTOs ==========

public class CreateExpenseRequest
{
    public int HouseId { get; set; }
    public int PaidByUserId { get; set; }
    public string Description { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string? Category { get; set; }
    public string? SplitType { get; set; } = "equal"; // equal, custom, people
    public List<CustomSplitInfo>? CustomSplits { get; set; }
    public List<int>? SelectedUserIds { get; set; }
}

public class CustomSplitInfo
{
    public int UserId { get; set; }
    public decimal Percentage { get; set; }
}

public class BalanceResponse
{
    public int HouseId { get; set; }
    public string HouseName { get; set; } = string.Empty;
    public List<UserBalanceInfo> Members { get; set; } = new();
    public List<DebtDetail> Debts { get; set; } = new();
    public List<SimplifiedPayment> SimplifiedPayments { get; set; } = new();
    public decimal TotalUnsettledAmount { get; set; }
}

public class UserBalanceInfo
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public decimal TotalOwes { get; set; }
    public decimal TotalOwed { get; set; }
    public decimal NetBalance { get; set; } // Dương = được nợ, Âm = đang nợ
}

public class UserBalanceResponse
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public decimal TotalOwes { get; set; }
    public decimal TotalOwed { get; set; }
    public decimal NetBalance { get; set; }
    public List<DebtDetail> DebtsOwing { get; set; } = new();
    public List<DebtDetail> DebtsOwed { get; set; } = new();
}

public class DebtDetail
{
    public int Id { get; set; }
    public int DebtorUserId { get; set; }
    public string DebtorName { get; set; } = string.Empty;
    public int CreditorUserId { get; set; }
    public string CreditorName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SimplifiedPayment
{
    public int FromUserId { get; set; }
    public string FromUserName { get; set; } = string.Empty;
    public int ToUserId { get; set; }
    public string ToUserName { get; set; } = string.Empty;
    public decimal Amount { get; set; }
}

public class SettleDebtRequest
{
    public int DebtId { get; set; }
}

public class SettlePartialRequest
{
    public int DebtId { get; set; }
    public decimal Amount { get; set; }
}
