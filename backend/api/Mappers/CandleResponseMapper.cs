using AutoMapper;
using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Mappers;

public sealed class CandleResponseMapper(AppDbContext db, IMapper mapper)
{
    public async Task<CandleResponse> Map(Candle candle, CancellationToken cancellationToken = default)
    {
        var count = await db.CandleSupports.CountAsync(s => s.CandleId == candle.Id, cancellationToken);
        var comments = await db.CandleComments.CountAsync(
            c => c.CandleId == candle.Id && c.DeletedAt == null && !c.User.IsDeleted, cancellationToken);
        return mapper.Map<CandleResponse>(candle) with { SupportersCount = count, CommentsCount = comments };
    }

    public async Task<List<CandleResponse>> Map(
        IReadOnlyCollection<Candle> candles,
        CancellationToken cancellationToken = default)
    {
        if (candles.Count == 0) return [];

        var ids = candles.Select(c => c.Id).ToArray();
        var counts = await db.CandleSupports
            .Where(s => ids.Contains(s.CandleId))
            .GroupBy(s => s.CandleId)
            .Select(g => new { CandleId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.CandleId, g => g.Count, cancellationToken);

        var comments = await db.CandleComments
            .Where(c => ids.Contains(c.CandleId) && c.DeletedAt == null && !c.User.IsDeleted)
            .GroupBy(c => c.CandleId)
            .Select(g => new { CandleId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(g => g.CandleId, g => g.Count, cancellationToken);

        return candles.Select(c => mapper.Map<CandleResponse>(c) with
        {
            SupportersCount = counts.GetValueOrDefault(c.Id),
            CommentsCount = comments.GetValueOrDefault(c.Id)
        }).ToList();
    }
}
