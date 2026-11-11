using System.Text;
using CandleBackend.BackgroundJobs;
using CandleBackend.Data;
using CandleBackend.Json;
using CandleBackend.Mappers;
using CandleBackend.Models;
using CandleBackend.Services;
using CandleBackend.WebPages;
using CandleBot;
using CandleBot.Preferences;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace CandleBackend;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);
        EnsureJwtKeyIsSafe(builder);

        // Add services to the container.
        builder.Services.AddDbContext<AppDbContext>(options =>
            options.UseNpgsql(
                builder.Configuration.GetConnectionString("Default"),
                npgsql => npgsql.UseNetTopologySuite()
            )
        );
        builder.Services.AddControllers();
        builder.Services.Configure<WebAppOptions>(builder.Configuration.GetSection("WebApp"));
        builder.Services.AddSingleton<WebAppPageRenderer>();
        builder.Services.AddHttpClient(nameof(WebAppPageRenderer), client => client.Timeout = TimeSpan.FromSeconds(5));
        builder.Services.AddSingleton<CandlePreviewRenderer>();
        builder.Services.AddScoped<IPasswordHasher<User>, PasswordHasher<User>>();
        builder.Services.Configure<PasswordHasherOptions>(o => o.IterationCount = 210_000);
        builder.Services.AddScoped<SessionIssuer>();
        builder.Services.AddScoped<CandleResponseMapper>();
        builder.Services.AddScoped<BotPreferences>();
        builder.Services.AddScoped<IBotPreferences>(provider => provider.GetRequiredService<BotPreferences>());
        builder.Services.AddCandleBot(builder.Configuration);
        builder.Services.Configure<Storage.S3StorageOptions>(builder.Configuration.GetSection("Storage"));
        builder.Services.AddSingleton<Storage.IMediaStorage, Storage.S3MediaStorage>();
        builder.Services.AddSingleton<ResourceImageProcessor>();
        builder.Services.AddHostedService<ResourceCleanupWorker>();
        builder.Services.AddHostedService<ResourcePreviewBackfillWorker>();
        builder.Services.AddDataProtection();
        builder.Services.AddSingleton<Pagination.CandleCursor>();
        builder.Services.AddSingleton<Pagination.CommentCursor>();

        // Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
        builder.Services.AddEndpointsApiExplorer();
        builder.Services.AddSwaggerGen(options => options.SchemaFilter<OptionalSchemaFilter>());

        builder.Services
            .AddAuthentication(options =>
            {
                options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
                options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
            })
            .AddJwtBearer(options =>
            {
                options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
                options.SaveToken = true;
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidateIssuer = true,
                    ValidIssuer = builder.Configuration["Jwt:Issuer"]!,
                    ValidateAudience = true,
                    ValidAudience = builder.Configuration["Jwt:Audience"]!,
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Key"]!)),
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.Zero,
                    NameClaimType = "id",
                    RoleClaimType = "role"
                };
            });

        builder.Services.AddAutoMapper(_ => { }, typeof(MappingProfile));

        const string devCorsPolicy = "DevCors";

        builder.Services.AddCors(options =>
        {
            options.AddPolicy(devCorsPolicy, policy =>
            {
                policy.AllowAnyOrigin()
                    .AllowAnyHeader()
                    .AllowAnyMethod();
            });
        });

        var app = builder.Build();

        using (var scope = app.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Database.Migrate();
        }

        app.Map(Routing.ApiRoutes.Prefix, api =>
        {
            api.UseRouting();
            api.UseSwagger();
            api.UseSwaggerUI(options => options.SwaggerEndpoint("v1/swagger.json", "Candle API"));
            api.UseCors(devCorsPolicy);
            api.UseAuthentication();
            api.UseAuthorization();
            api.UseEndpoints(endpoints => endpoints.MapControllers());
        });

        app.MapCandlePages();

        app.Run();
    }

    // Tokens signed with a known key can be forged by anyone who has read the
    // repository, so outside Development the key must come from the environment.
    private static void EnsureJwtKeyIsSafe(WebApplicationBuilder builder)
    {
        var key = builder.Configuration["Jwt:Key"];
        if (string.IsNullOrWhiteSpace(key) || Encoding.UTF8.GetByteCount(key) < 32)
            throw new InvalidOperationException(
                "Jwt:Key must be set (at least 32 bytes). Set the JWT_KEY environment variable.");

        if (builder.Environment.IsDevelopment()) return;

        string[] placeholders = ["CHANGE_ME", "DEV_", "local-development-only"];
        if (placeholders.Any(p => key.Contains(p, StringComparison.OrdinalIgnoreCase)))
            throw new InvalidOperationException(
                "Jwt:Key looks like a development placeholder. Generate a real key for non-Development environments.");
    }
}
