using CandleBackend.Data;
using CandleBackend.Models;

namespace CandleBackend.Extensions;

public static class CandleQueryExtensions
{
    public static IQueryable<Candle> VisibleTo(this IQueryable<Candle> candles, AppDbContext db, long? userId)
    {
        return userId is { } id
            ? candles.Where(c => !db.UserBlocks.Any(b => b.UserId == id && b.BlockedUserId == c.UserId))
            : candles;
    }
}
