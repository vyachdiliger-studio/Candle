using System.Net;
using Amazon.S3;
using AutoMapper;
using CandleBackend.Data;
using CandleBackend.Dtos;
using CandleBackend.Extensions;
using CandleBackend.Models;
using CandleBackend.Services;
using CandleBackend.Storage;
using ImageMagick;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Controllers;

[ApiController]
[Authorize]
[Route("resources")]
public sealed class ResourcesController(AppDbContext db, IMediaStorage storage,
    ResourceImageProcessor processor, IMapper mapper) : ControllerBase
{
    [HttpPost]
    public async Task<ActionResult<ResourceUploadResponse>> Create(CancellationToken cancellationToken)
    {
        var id = Guid.NewGuid();
        var expires = DateTime.UtcNow.AddMinutes(10);
        var resource = new MediaResource
        {
            Id = id,
            OwnerId = User.GetId(),
            CreatedAt = DateTime.UtcNow,
            UploadKey = $"uploads/{id}",
            StorageKey = $"resources/{id}/image.webp",
            ThumbnailKey = $"resources/{id}/thumbnail.webp",
            PreviewKey = $"resources/{id}/preview.jpg"
        };
        var url = await storage.CreateUploadUrl(resource.UploadKey, expires);
        db.MediaResources.Add(resource);
        await db.SaveChangesAsync(cancellationToken);
        return Ok(new ResourceUploadResponse(id, url, expires));
    }

    [HttpPost("{id:guid}/complete")]
    public async Task<ActionResult<ResourceResponse>> Complete(Guid id, CancellationToken cancellationToken)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(cancellationToken);
        var resource = await db.MediaResources.FromSqlInterpolated(
            $"SELECT * FROM \"MediaResources\" WHERE \"Id\" = {id} FOR UPDATE")
            .SingleOrDefaultAsync(cancellationToken);
        if (resource == null) return NotFound();
        if (resource.OwnerId != User.GetId()) return Forbid();
        if (resource.ReadyAt != null) return Ok(mapper.Map<ResourceResponse>(resource));
        if (resource.CreatedAt < DateTime.UtcNow.AddHours(-24)) return Conflict("resource_expired");
        try
        {
            var bytes = await storage.Read(resource.UploadKey, cancellationToken);
            var processed = processor.Process(bytes, cancellationToken);
            // The upload URL remains reusable until expiry; publish under separate immutable keys.
            await storage.Write(resource.StorageKey, processed.Image, "image/webp", cancellationToken);
            await storage.Write(resource.ThumbnailKey, processed.Thumbnail, "image/webp", cancellationToken);
            resource.PreviewKey ??= $"resources/{id}/preview.jpg";
            await storage.Write(resource.PreviewKey, processed.Preview, "image/jpeg", cancellationToken);
            resource.ContentType = "image/webp";
            resource.Size = processed.Image.Length;
            resource.Width = processed.Width;
            resource.Height = processed.Height;
            resource.ReadyAt = DateTime.UtcNow;
            await db.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);
            return Ok(mapper.Map<ResourceResponse>(resource));
        }
        catch (AmazonS3Exception error) when (error.StatusCode == HttpStatusCode.NotFound)
        {
            return Conflict("upload_not_found");
        }
        catch (InvalidDataException error)
        {
            return BadRequest(error.Message);
        }
        catch (MagickException)
        {
            return BadRequest("invalid_image");
        }
    }

    [AllowAnonymous]
    [HttpGet("{id:guid}/content")]
    public Task<IActionResult> Content(Guid id, CancellationToken cancellationToken) =>
        Download(id, false, cancellationToken);

    [AllowAnonymous]
    [HttpGet("{id:guid}/thumbnail")]
    public Task<IActionResult> Thumbnail(Guid id, CancellationToken cancellationToken) =>
        Download(id, true, cancellationToken);

    [AllowAnonymous]
    [HttpGet("{id:guid}/preview.jpg")]
    [HttpGet("{id:guid}/candle-preview.jpg")]
    public async Task<IActionResult> Preview(Guid id, CancellationToken cancellationToken)
    {
        var resource = await db.MediaResources.AsNoTracking()
            .SingleOrDefaultAsync(r => r.Id == id && r.ReadyAt != null, cancellationToken);
        if (resource is null) return NotFound();

        if (resource.PreviewKey is null)
        {
            Response.Headers.CacheControl = "no-store";
            return Redirect("/api/previews/candles/v1/default.jpg");
        }

        var bytes = await storage.Read(resource.PreviewKey, cancellationToken);
        Response.Headers.CacheControl = "public,max-age=31536000,immutable";
        return File(bytes, "image/jpeg");
    }

    private async Task<IActionResult> Download(Guid id, bool thumbnail, CancellationToken cancellationToken)
    {
        var resource = await db.MediaResources.AsNoTracking().SingleOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (resource?.ReadyAt == null) return NotFound();
        var bytes = await storage.Read(thumbnail ? resource.ThumbnailKey : resource.StorageKey, cancellationToken);
        Response.Headers.CacheControl = "public,max-age=31536000,immutable";
        return File(bytes, resource.ContentType!);
    }
}
