using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace CandleBackend.Controllers;

[ApiController]
[Authorize]
[Route("users/me/blocks")]
public sealed class UserBlocksController(AppDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<List<BlockedUserResponse>>> List(CancellationToken cancellationToken)
    {
        var userId = User.GetId();
        return await db.UserBlocks.AsNoTracking()
            .Where(b => b.UserId == userId)
            .OrderBy(b => b.BlockedUser.Username).ThenBy(b => b.BlockedUserId)
            .Select(b => new BlockedUserResponse(b.BlockedUserId, b.BlockedUser.Username))
            .ToListAsync(cancellationToken);
    }

    [HttpPut("{id:long}")]
    public async Task<IActionResult> Block(long id, CancellationToken cancellationToken)
    {
        var userId = User.GetId();
        if (id == userId) return BadRequest("cannot_block_yourself");
        if (!await db.Users.AnyAsync(u => u.Id == id && !u.IsDeleted, cancellationToken))
            return NotFound();
        if (await db.UserBlocks.AnyAsync(b => b.UserId == userId && b.BlockedUserId == id, cancellationToken))
            return NoContent();

        db.UserBlocks.Add(new UserBlock
        {
            UserId = userId,
            BlockedUserId = id,
            CreatedAt = DateTime.UtcNow
        });

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException error) when (error.InnerException is PostgresException
        { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            // Concurrent retries of the same block are successful too.
        }

        return NoContent();
    }

    [HttpDelete("{id:long}")]
    public async Task<IActionResult> Unblock(long id, CancellationToken cancellationToken)
    {
        var userId = User.GetId();
        await db.UserBlocks.Where(b => b.UserId == userId && b.BlockedUserId == id)
            .ExecuteDeleteAsync(cancellationToken);
        return NoContent();
    }
}
