using CandleBackend.Models;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Data;

public sealed class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<ContentReport> ContentReports => Set<ContentReport>();
    public DbSet<UserBlock> UserBlocks => Set<UserBlock>();
    public DbSet<TelegramUserSettings> TelegramUserSettings => Set<TelegramUserSettings>();
    public DbSet<MediaResource> MediaResources => Set<MediaResource>();
    public DbSet<User> Users => Set<User>();
    public DbSet<CandleSupport> CandleSupports => Set<CandleSupport>();
    public DbSet<Candle> Candles => Set<Candle>();
    public DbSet<UserLogin> UserLogins => Set<UserLogin>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();

    protected override void OnModelCreating(ModelBuilder b)
    {
        b.HasPostgresExtension("postgis");

        b.Entity<User>().Property(x => x.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

        b.Entity<Candle>(e =>
        {
            e.Property(x => x.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

            e.Property(x => x.MercatorX)
                .HasComputedColumnSql("ST_X(ST_Transform(\"Location\", 3857))", stored: true);

            e.Property(x => x.MercatorY)
                .HasComputedColumnSql("ST_Y(ST_Transform(\"Location\", 3857))", stored: true);

            e.HasIndex(x => x.Location).HasMethod("gist");
        });

        b.Entity<Candle>().Navigation(x => x.BackgroundResource).AutoInclude();

        b.Entity<UserLogin>().Property(x => x.ProviderData)
            .HasDefaultValueSql("'{}'::jsonb");

        b.Entity<RefreshToken>().Property(x => x.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

        b.Entity<User>().Property(x => x.IsDeleted).HasDefaultValue(false);
    }
}
