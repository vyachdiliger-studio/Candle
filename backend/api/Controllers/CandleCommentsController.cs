using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Models;
using CandleBackend.Pagination;
using CandleBackend.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Controllers;

/// <summary>
/// A candle's comment thread. Reading is public; writing needs a session.
/// See docs/backend/candle-comments.md for the contract.
/// </summary>
[ApiController]
[Authorize]
[Route("candles/{candleId:long}/comments")]
public sealed class CandleCommentsController(AppDbContext db, CommentCursor cursors) : ControllerBase
{
    public const int DefaultPageSize = 20;
    public const int MaxPageSize = 50;

    /// <summary>Keeps <see cref="CandleComment.Path"/> well below its column limit.</summary>
    public const int MaxDepth = 100;

    [AllowAnonymous]
    [HttpGet]
    public async Task<ActionResult<CandleCommentPage>> List(
        long candleId,
        [FromQuery] string? cursor,
        [FromQuery] int limit = DefaultPageSize,
        CancellationToken cancellationToken = default)
    {
        if (!await CandleExists(candleId, cancellationToken)) return NotFound("candle_not_found");
        return await Page(candleId, null, $"candle:{candleId}", cursor, limit, newestFirst: true,
            cancellationToken);
    }

    [AllowAnonymous]
    [HttpGet("{commentId:long}/replies")]
    public async Task<ActionResult<CandleCommentPage>> Replies(
        long candleId,
        long commentId,
        [FromQuery] string? cursor,
        [FromQuery] int limit = DefaultPageSize,
        CancellationToken cancellationToken = default)
    {
        if (!await CandleExists(candleId, cancellationToken)) return NotFound("candle_not_found");
        if (!await db.CandleComments.AnyAsync(
                c => c.Id == commentId && c.CandleId == candleId && c.DeletedAt == null, cancellationToken))
            return NotFound("comment_not_found");
        return await Page(candleId, commentId, $"replies:{commentId}", cursor, limit, newestFirst: false,
            cancellationToken);
    }

    [HttpPost]
    public async Task<ActionResult<CandleCommentResponse>> Create(
        long candleId,
        [FromBody] CreateCandleCommentRequest body,
        CancellationToken cancellationToken)
    {
        var text = CommentRules.CleanText(body.Text);
        if (text is null) return BadRequest("invalid_comment_text");
        if (!await CandleExists(candleId, cancellationToken)) return NotFound("candle_not_found");

        var comment = new CandleComment
        {
            CandleId = candleId,
            UserId = User.GetId(),
            Text = text,
            CreatedAt = DateTime.UtcNow
        };

        if (body.ParentCommentId is { } parentId)
        {
            var parent = await db.CandleComments.AsNoTracking()
                .Where(c => c.Id == parentId)
                .Select(c => new { c.Id, c.CandleId, c.RootCommentId, c.Path, c.Depth, c.DeletedAt, c.User.IsDeleted })
                .SingleOrDefaultAsync(cancellationToken);
            // A deleted comment is only a placeholder; it cannot be answered.
            if (parent is null || parent.DeletedAt != null || parent.IsDeleted)
                return NotFound("comment_not_found");
            if (parent.CandleId != candleId) return BadRequest("parent_not_in_candle");
            if (parent.Depth >= MaxDepth) return BadRequest("thread_too_deep");

            comment.ParentCommentId = parent.Id;
            comment.RootCommentId = parent.RootCommentId ?? parent.Id;
            comment.Path = $"{parent.Path}{parent.Id}/";
            comment.Depth = parent.Depth + 1;
        }

        db.CandleComments.Add(comment);
        await db.SaveChangesAsync(cancellationToken);
        await db.Entry(comment).Reference(c => c.User).LoadAsync(cancellationToken);

        return StatusCode(StatusCodes.Status201Created, ToResponse(comment, 0));
    }

    [HttpDelete("{commentId:long}")]
    public async Task<IActionResult> Delete(long candleId, long commentId, CancellationToken cancellationToken)
    {
        var comment = await db.CandleComments
            .SingleOrDefaultAsync(c => c.Id == commentId && c.CandleId == candleId && c.DeletedAt == null,
                cancellationToken);
        if (comment is null) return NotFound("comment_not_found");
        if (comment.UserId != User.GetId()) return StatusCode(StatusCodes.Status403Forbidden, "forbidden");

        // The comment goes away together with its whole branch, as in TikTok or Instagram.
        var now = DateTime.UtcNow;
        var branch = comment.DescendantPath;
        await db.CandleComments
            .Where(c => c.CandleId == candleId && c.DeletedAt == null
                && (c.Id == commentId || c.Path.StartsWith(branch)))
            .ExecuteUpdateAsync(setters => setters.SetProperty(c => c.DeletedAt, now), cancellationToken);
        return NoContent();
    }

    private async Task<ActionResult<CandleCommentPage>> Page(
        long candleId,
        long? parentId,
        string scope,
        string? cursor,
        int limit,
        bool newestFirst,
        CancellationToken cancellationToken)
    {
        if (limit is < 1 or > MaxPageSize) return BadRequest("invalid_limit");
        var position = cursor is null ? null : cursors.Decode(cursor, scope);
        if (cursor is not null && position is null) return BadRequest("invalid_cursor");

        var siblings = parentId is { } id
            ? db.CandleComments.Where(c => c.CandleId == candleId && c.ParentCommentId == id)
            : db.CandleComments.Where(c => c.CandleId == candleId && c.ParentCommentId == null);

        // Deleting a comment deletes its branch, so deleted comments are never listed.
        // Live = the author still has an account; a comment of a deleted account stays
        // as a placeholder while live replies remain below it.
        var rows = siblings.AsNoTracking().Where(c => c.DeletedAt == null).Select(c => new
        {
            c.Id,
            c.ParentCommentId,
            c.RootCommentId,
            c.Depth,
            c.Text,
            c.CreatedAt,
            c.UserId,
            c.User.Username,
            Live = !c.User.IsDeleted,
            Replies = db.CandleComments.Count(d => d.CandleId == candleId
                && d.Path.StartsWith(c.Path + c.Id.ToString() + "/")
                && d.DeletedAt == null && !d.User.IsDeleted)
        }).Where(r => r.Live || r.Replies > 0);

        if (position is not null)
        {
            rows = newestFirst
                ? rows.Where(r => r.CreatedAt < position.CreatedAt
                    || (r.CreatedAt == position.CreatedAt && r.Id < position.Id))
                : rows.Where(r => r.CreatedAt > position.CreatedAt
                    || (r.CreatedAt == position.CreatedAt && r.Id > position.Id));
        }

        rows = newestFirst
            ? rows.OrderByDescending(r => r.CreatedAt).ThenByDescending(r => r.Id)
            : rows.OrderBy(r => r.CreatedAt).ThenBy(r => r.Id);

        var items = await rows.Take(limit + 1).ToListAsync(cancellationToken);
        var hasMore = items.Count > limit;
        if (hasMore) items.RemoveAt(items.Count - 1);
        var next = hasMore ? cursors.Encode(items[^1].CreatedAt, items[^1].Id, scope) : null;

        var page = items.Select(r => new CandleCommentResponse(
            r.Id,
            candleId,
            r.ParentCommentId,
            r.RootCommentId,
            r.Depth,
            r.Live ? new CandleAuthorDto(r.UserId, r.Username) : null,
            r.Live ? r.Text : null,
            !r.Live,
            r.CreatedAt,
            r.Replies)).ToList();
        return Ok(new CandleCommentPage(page, next));
    }

    private Task<bool> CandleExists(long candleId, CancellationToken cancellationToken) =>
        db.Candles.VisibleTo(db, User.Identity?.IsAuthenticated == true ? User.GetId() : null)
            .AnyAsync(c => c.Id == candleId, cancellationToken);

    private static CandleCommentResponse ToResponse(CandleComment c, int replies) => new(
        c.Id,
        c.CandleId,
        c.ParentCommentId,
        c.RootCommentId,
        c.Depth,
        new CandleAuthorDto(c.UserId, c.User.Username),
        c.Text,
        false,
        c.CreatedAt,
        replies);
}
