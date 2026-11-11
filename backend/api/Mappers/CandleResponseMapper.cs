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
        return mapper.Map<CandleResponse>(candle) with { SupportersCount = count };
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

        return candles.Select(c => mapper.Map<CandleResponse>(c) with
        {
            SupportersCount = counts.GetValueOrDefault(c.Id)
        }).ToList();
    }
}
