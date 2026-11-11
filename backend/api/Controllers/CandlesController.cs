using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Geo;
using CandleBackend.Mappers;
using CandleBackend.Models;
using CandleBackend.Pagination;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace CandleBackend.Controllers;

[ApiController]
[Authorize]
[Route("candles")]
public class CandlesController(AppDbContext db, CandleResponseMapper responses, CandleCursor cursors) : ControllerBase
{
    private IQueryable<Candle> VisibleCandles => db.Candles.VisibleTo(
        db, User.Identity?.IsAuthenticated == true ? User.GetId() : null);

    [AllowAnonymous]
    [HttpPost("search")]
    public async Task<ActionResult<CandlePage>> Search(
        [FromBody]
        SearchCandlesRequest request,
        CancellationToken cancellationToken
    )
    {
        if (request.Filter is null || request.Sort != "createdAtDesc"
            || request.Filter.Status is not (null or "burning" or "extinguished")
            || request.Filter.Ids?.Any(id => id <= 0) == true)
            return BadRequest("invalid_candle_filter");

        var queryKey = CandleCursor.QueryKey(request);
        var position = request.Cursor is null ? null : cursors.Decode(request.Cursor, queryKey);
        if (request.Cursor is not null && position is null)
            return BadRequest("invalid_cursor");

        var now = DateTime.UtcNow;
        var query = VisibleCandles.AsNoTracking();
        if (request.Filter.AuthorId is { } authorId)
            query = query.Where(c => c.UserId == authorId);
        if (request.Filter.Ids is { } ids)
            query = query.Where(c => ids.Contains(c.Id));
        if (request.Filter.Status == "burning")
            query = query.Where(c => c.IgnitedAt <= now && c.ExtinguishedAt > now);
        if (request.Filter.Status == "extinguished")
            query = query.Where(c => c.ExtinguishedAt <= now);
        if (position is not null)
            query = query.Where(c => c.CreatedAt < position.CreatedAt
                || (c.CreatedAt == position.CreatedAt && c.Id < position.Id));

        var candles = await query.Include(c => c.User)
            .OrderByDescending(c => c.CreatedAt).ThenByDescending(c => c.Id)
            .Take(request.Limit + 1).ToListAsync(cancellationToken);
        var hasMore = candles.Count > request.Limit;
        if (hasMore) candles.RemoveAt(candles.Count - 1);
        var nextCursor = hasMore
            ? cursors.Encode(candles[^1].CreatedAt, candles[^1].Id, queryKey) : null;
        return Ok(new CandlePage(await responses.Map(candles, cancellationToken), nextCursor));
    }

    [HttpPost]
    public async Task<ActionResult<CandleResponse>> Create([FromBody] CreateCandleRequest body)
    {
        var now = DateTime.UtcNow;
        var userId = User.GetId();
        await using var transaction = await db.Database.BeginTransactionAsync();
        if (body.BackgroundResourceId is { } resourceId && !await CanAttach(resourceId, userId))
            return BadRequest("invalid_background_resource");

        var address = CleanAddress(body.Address);
        if (address is not null && body.Location is null) return BadRequest("address_requires_location");

        var candle = new Candle
        {
            UserId = userId,
            BackgroundResourceId = body.BackgroundResourceId,
            Message = body.Message?.Trim(),
            Address = address,
            CreatedAt = now,
            IgnitedAt = now,
            ExtinguishedAt = now.AddDays(30),
            Location = body.Location is null
                ? null
                // Point takes x then y, so longitude comes first.
                : new Point(body.Location.Longitude, body.Location.Latitude) { SRID = 4326 }
        };

        db.Candles.Add(candle);

        await db.SaveChangesAsync();

        await transaction.CommitAsync();
        await db.Entry(candle).Reference(c => c.BackgroundResource).LoadAsync();
        await db.Entry(candle).Reference(c => c.User).LoadAsync();
        return CreatedAtAction(nameof(GetById), new { id = candle.Id }, await responses.Map(candle, HttpContext.RequestAborted));
    }

    [HttpPatch("{id:long}")]
    public async Task<ActionResult<CandleResponse>> Patch(long id, [FromBody] UpdateCandleRequest body)
    {
        var userId = User.GetId();
        var candle = await VisibleCandles.Include(c => c.User).FirstOrDefaultAsync(x => x.Id == id);

        if (candle is null) return NotFound();

        if (candle.UserId != userId) return Forbid();

        await using var transaction = await db.Database.BeginTransactionAsync();
        if (!body.BackgroundResourceId.IsUndefined)
        {
            var resourceId = body.BackgroundResourceId.ValueOrDefault;
            if (resourceId is { } value && !await CanAttach(value, userId))
                return BadRequest("invalid_background_resource");
            candle.BackgroundResourceId = resourceId;
            candle.BackgroundResource = resourceId is { } attached
                ? await db.MediaResources.FindAsync(attached) : null;
        }

        if (!body.Message.IsUndefined)
        {
            var message = body.Message.ValueOrDefault?.Trim();

            candle.Message = string.IsNullOrEmpty(message) ? null : message;
        }

        var address = body.Address.IsUndefined ? null : CleanAddress(body.Address.ValueOrDefault);
        if (address is { Length: > Candle.AddressMaxLength }) return BadRequest("address_too_long");

        if (!body.Location.IsUndefined)
        {
            var location = body.Location.ValueOrDefault;

            if (location is null)
            {
                candle.Location = null;
            }
            else
            {
                // Beyond the Mercator limit ST_Transform runs off to infinity, which
                // would poison the generated columns every tile query reads.
                if (location.Longitude is < -180 or > 180
                    || Math.Abs(location.Latitude) > WebMercator.MaxLatitude)
                    return BadRequest("location_out_of_range");

                // Point takes x then y, so longitude comes first.
                candle.Location = new Point(location.Longitude, location.Latitude) { SRID = 4326 };
            }

            // An address described the old spot, so only one sent along survives.
            candle.Address = candle.Location is null ? null : address;
        }
        else if (!body.Address.IsUndefined)
        {
            if (address is not null && candle.Location is null)
                return BadRequest("address_requires_location");

            candle.Address = address;
        }

        await db.SaveChangesAsync();

        await transaction.CommitAsync();
        return Ok(await responses.Map(candle, HttpContext.RequestAborted));
    }

    private static string? CleanAddress(string? address)
    {
        var trimmed = address?.Trim();

        return string.IsNullOrEmpty(trimmed) ? null : trimmed;
    }

    [HttpPost("{id:long}/boost")]
    public async Task<ActionResult<CandleResponse>> Boost(long id, [FromBody] BoostCandleRequest body)
    {
        var candle = await VisibleCandles.Include(c => c.User).FirstOrDefaultAsync(x => x.Id == id);

        if (candle is null) return NotFound();

        if (body.Taps is < 1 or > 10000) return BadRequest("invalid_taps");

        var now = DateTime.UtcNow;

        if (candle.ExtinguishedAt <= now)
            return Conflict("candle_extinguished");

        await using var transaction = await db.Database.BeginTransactionAsync(HttpContext.RequestAborted);
        var delta = TimeSpan.FromSeconds(body.Taps);
        // Apply concurrent supporters atomically instead of overwriting another tap batch.
        var changed = await db.Candles.Where(c => c.Id == id && c.ExtinguishedAt > now)
            .ExecuteUpdateAsync(setters => setters
                .SetProperty(c => c.IgnitedAt, c => c.IgnitedAt + delta <= now ? c.IgnitedAt + delta : now)
                .SetProperty(c => c.ExtinguishedAt, c => c.ExtinguishedAt + delta));
        if (changed == 0) return Conflict("candle_extinguished");
        var userId = User.GetId();
        if (userId != candle.UserId)
        {
            await db.Database.ExecuteSqlInterpolatedAsync($"""
                INSERT INTO "CandleSupports" ("CandleId", "UserId", "CreatedAt")
                VALUES ({id}, {userId}, {now})
                ON CONFLICT ("CandleId", "UserId") DO NOTHING
                """, HttpContext.RequestAborted);
        }

        await transaction.CommitAsync(HttpContext.RequestAborted);
        await db.Entry(candle).ReloadAsync();
        return Ok(await responses.Map(candle, HttpContext.RequestAborted));
    }

    // Compatibility for older clients; new clients use search.

    [HttpGet("active")]
    public async Task<ActionResult<CandleResponse>> GetActive()
    {
        var userId = User.GetId();
        var now = DateTime.UtcNow;

        var candle = await VisibleCandles
            .AsNoTracking()
            .Include(x => x.User)
            .Where(x => x.UserId == userId && x.IgnitedAt <= now && x.ExtinguishedAt > now)
            .FirstOrDefaultAsync();

        if (candle is null) return NotFound();

        return Ok(await responses.Map(candle, HttpContext.RequestAborted));
    }

    [AllowAnonymous]
    [HttpGet("{id:long}")]
    public async Task<ActionResult<CandleResponse>> GetById(long id)
    {
        // The author is included here because this is what backs the map's
        // preview card, which names who lit the candle.
        var candle = await VisibleCandles
            .AsNoTracking()
            .Include(x => x.User)
            .FirstOrDefaultAsync(x => x.Id == id);

        if (candle is null) return NotFound();

        return Ok(await responses.Map(candle, HttpContext.RequestAborted));
    }

    /// <summary>
    /// Candles inside one XYZ tile, grouped into a grid so the response stays
    /// small however dense the area is.
    ///
    /// Nothing is dropped and there is no result limit: the grid bounds the
    /// response by itself, because a cell collapses to one row no matter how
    /// many candles it holds. A million candles in one spot is one cluster with
    /// a count of a million, not a million rows and not a truncated list.
    /// </summary>
    /// <param name="cellsPerTile">
    /// Grid subdivision per axis. Higher means smaller, more numerous bubbles;
    /// the response holds at most this squared clusters.
    /// </param>
    [AllowAnonymous]
    [HttpGet("tiles/{z:int}/{x:int}/{y:int}")]
    public async Task<ActionResult<TileResponse>> GetTile(
        int z,
        int x,
        int y,
        [FromQuery] int cellsPerTile = 8)
    {
        if (!WebMercator.IsValidTile(z, x, y)) return NotFound();

        if (cellsPerTile is < 1 or > 64) return BadRequest("cells_per_tile_out_of_range");

        var now = DateTime.UtcNow;
        var (minLon, minLat, maxLon, maxLat) = WebMercator.TileBounds(z, x, y);

        // A tile is a rectangle in projected space, and Mercator is cylindrical,
        // so it is a rectangle in lon/lat too - this envelope is exact. Building
        // it here rather than comparing columns is what lets the GiST index take
        // the query; it also means a tile can never straddle the antimeridian,
        // since the seam is a tile boundary by construction.
        var envelope = new Envelope(minLon, maxLon, minLat, maxLat);
        var viewport = new GeometryFactory(new PrecisionModel(), 4326).ToGeometry(envelope);

        var cell = WebMercator.CellSize(z, cellsPerTile);
        long? userId = User.Identity?.IsAuthenticated == true ? User.GetId() : null;

        // Cell indices come from a single world-wide grid rather than an offset
        // within this tile, so neighbouring tiles agree on where cells fall and
        // the same cluster keeps its position as the client pans.
        var cells = await VisibleCandles
            .AsNoTracking()
            .Where(c => c.Location != null
                && c.ExtinguishedAt > now
                && viewport.Intersects(c.Location))
            .GroupBy(c => new
            {
                Col = Math.Floor(c.MercatorX!.Value / cell),
                Row = Math.Floor(c.MercatorY!.Value / cell)
            })
            .Select(g => new
            {
                Count = g.Count(),
                Latitude = g.Average(c => c.Location!.Y),
                Longitude = g.Average(c => c.Location!.X),
                CandleId = g.Max(c => c.Id),
                HasOwnCandle = g.Count(c => c.UserId == userId) > 0
            })
            .ToListAsync();

        var clusters = cells
            .Select(c => new ClusterResponse(
                c.Count,
                new LocationDto(c.Latitude, c.Longitude),
                c.CandleId,
                c.HasOwnCandle))
            .ToList();

        return Ok(new TileResponse(z, x, y, cellsPerTile, clusters));
    }

    private async Task<bool> CanAttach(Guid id, long ownerId)
    {
        var resource = await db.MediaResources.FromSqlInterpolated(
            $"SELECT * FROM \"MediaResources\" WHERE \"Id\" = {id} FOR UPDATE").AsNoTracking().SingleOrDefaultAsync();
        return resource?.OwnerId == ownerId && resource.ReadyAt != null;
    }
}
