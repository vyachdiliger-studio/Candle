using AutoMapper;
using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Controllers;

[ApiController]
[Authorize]
[Route("users/me")]
public class UsersController(AppDbContext db, IMapper mapper) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<UserResponse>> GetMe()
    {
        var userId = User.GetId();

        var user = await db.Users
            .AsNoTracking()
            .Include(x => x.UserLogins)
            .FirstOrDefaultAsync(x => x.Id == userId && !x.IsDeleted);

        if (user is null) return NotFound();

        return Ok(mapper.Map<UserResponse>(user));
    }

    [HttpPatch]
    public async Task<ActionResult<UserResponse>> UpdateMe([FromBody] UpdateUserRequest body)
    {
        var userId = User.GetId();

        var user = await db.Users.Include(x => x.UserLogins).FirstOrDefaultAsync(x => x.Id == userId && !x.IsDeleted);

        if (user is null) return NotFound();

        if (!body.Username.IsUndefined)
        {
            var normalized = body.Username.ValueOrDefault?.Trim();

            if (string.IsNullOrEmpty(normalized))
            {
                return BadRequest("username_required");
            }
            else
            {
                if (!LoginRules.ValidUsername(normalized))
                    return BadRequest("invalid_username");
                var exists = await db.Users.AnyAsync(x =>
                    x.Username == normalized &&
                    x.Id != userId
                );

                if (exists) return Conflict("username_taken");

                user.Username = normalized;
            }
        }

        try { await db.SaveChangesAsync(); }
        catch (DbUpdateException e) when (e.InnerException is Npgsql.PostgresException { SqlState: "23505" })
        { return Conflict("username_taken"); }

        return Ok(mapper.Map<UserResponse>(user));
    }

    [HttpDelete]
    public async Task<IActionResult> DeleteMe()
    {
        var userId = User.GetId();

        var user = await db.Users.FirstOrDefaultAsync(x => x.Id == userId && !x.IsDeleted);

        if (user is null) return NotFound();

        user.IsDeleted = true;

        var tokens = await db.RefreshTokens.Where(x => x.UserId == userId && x.RevokedAt == null).ToListAsync();

        tokens.ForEach(x => x.RevokedAt = DateTime.UtcNow);

        await db.SaveChangesAsync();

        return NoContent();
    }
}
