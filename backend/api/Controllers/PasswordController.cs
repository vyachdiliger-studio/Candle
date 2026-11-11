using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Models;
using CandleBackend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Controllers;

[ApiController]
public class PasswordController(AppDbContext db, IPasswordHasher<User> hasher, SessionIssuer sessions) : ControllerBase
{
    public record LoginRequest(string Username, string Password);
    public record SetPasswordRequest(string? CurrentPassword, string NewPassword);

    [AllowAnonymous]
    [HttpPost("auth/password")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest request)
    {
        if (!LoginRules.ValidUsername(request.Username)) return BadRequest("invalid_username");
        if (!LoginRules.ValidPassword(request.Password)) return BadRequest("invalid_password_length");

        var user = await db.Users.Include(x => x.UserLogins)
            .SingleOrDefaultAsync(x => x.Username == request.Username);
        if (user == null)
        {
            user = new User { Username = request.Username };
            db.UserLogins.Add(new UserLogin
            {
                User = user,
                Provider = AuthProviderType.UsernamePassword,
                PasswordHash = hasher.HashPassword(user, request.Password),
                ProviderData = "{}"
            });
            try { await db.SaveChangesAsync(); }
            catch (DbUpdateException e) when (e.InnerException is Npgsql.PostgresException { SqlState: "23505" })
            {
                // A concurrent registration must never sign in without checking its password.
                return Conflict("username_taken");
            }
        }
        else
        {
            if (user.IsDeleted) return Unauthorized("invalid_credentials");
            var login = user.UserLogins.SingleOrDefault(x => x.Provider == AuthProviderType.UsernamePassword);
            if (login?.PasswordHash == null) return Unauthorized("invalid_credentials");
            var verification = hasher.VerifyHashedPassword(user, login.PasswordHash, request.Password);
            if (verification == PasswordVerificationResult.Failed) return Unauthorized("invalid_credentials");
            if (verification == PasswordVerificationResult.SuccessRehashNeeded)
            {
                login.PasswordHash = hasher.HashPassword(user, request.Password);
                try { await db.SaveChangesAsync(); }
                catch (DbUpdateConcurrencyException) { return Conflict("credentials_changed"); }
            }
        }
        return Ok(await sessions.Issue(user.Id));
    }

    [Authorize]
    [HttpPut("users/me/password")]
    public async Task<IActionResult> SetPassword(SetPasswordRequest request)
    {
        if (!LoginRules.ValidPassword(request.NewPassword)) return BadRequest("invalid_password_length");
        var user = await db.Users.Include(x => x.UserLogins)
            .SingleOrDefaultAsync(x => x.Id == User.GetId() && !x.IsDeleted);
        if (user == null) return NotFound();
        var login = user.UserLogins.SingleOrDefault(x => x.Provider == AuthProviderType.UsernamePassword);
        if (login != null)
        {
            if (string.IsNullOrEmpty(request.CurrentPassword) ||
                hasher.VerifyHashedPassword(user, login.PasswordHash!, request.CurrentPassword)
                    == PasswordVerificationResult.Failed)
                return BadRequest("incorrect_current_password");
            login.PasswordHash = hasher.HashPassword(user, request.NewPassword);
        }
        else
        {
            db.UserLogins.Add(new UserLogin
            {
                User = user,
                Provider = AuthProviderType.UsernamePassword,
                PasswordHash = hasher.HashPassword(user, request.NewPassword),
                ProviderData = "{}"
            });
        }
        try { await db.SaveChangesAsync(); }
        catch (DbUpdateConcurrencyException) { return Conflict("credentials_changed"); }
        catch (DbUpdateException e) when (e.InnerException is Npgsql.PostgresException { SqlState: "23505" })
        { return Conflict("credentials_changed"); }
        return NoContent();
    }
}
