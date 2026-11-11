using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Controllers;

[ApiController]
[Authorize]
[Route("reports")]
public sealed class ReportsController(AppDbContext db) : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> Create(CreateReportRequest request, CancellationToken cancellationToken)
    {
        var targets = new[] { request.CandleId, request.UserId, request.CommentId }.Count(t => t.HasValue);
        if (targets != 1) return BadRequest("report_target_required");

        var reporterId = User.GetId();
        var targetId = request switch
        {
            { CandleId: { } candleId } => await db.Candles.Where(c => c.Id == candleId)
                .Select(c => (long?)c.UserId).SingleOrDefaultAsync(cancellationToken),
            { CommentId: { } commentId } => await db.CandleComments
                .Where(c => c.Id == commentId && c.DeletedAt == null && !c.User.IsDeleted)
                .Select(c => (long?)c.UserId).SingleOrDefaultAsync(cancellationToken),
            _ => await db.Users.Where(u => u.Id == request.UserId && !u.IsDeleted)
                .Select(u => (long?)u.Id).SingleOrDefaultAsync(cancellationToken)
        };

        if (targetId is null) return NotFound();
        if (targetId == reporterId) return BadRequest("cannot_report_yourself");

        var report = new ContentReport
        {
            ReporterId = reporterId,
            ReportedUserId = targetId.Value,
            CandleId = request.CandleId,
            CommentId = request.CommentId,
            Reason = request.Reason,
            Details = request.Details?.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        db.ContentReports.Add(report);
        await db.SaveChangesAsync(cancellationToken);

        return StatusCode(StatusCodes.Status201Created, new { report.Id });
    }
}
