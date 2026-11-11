using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CandleBackend.Migrations
{
    /// <inheritdoc />
    public partial class ResourcePreview : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "PreviewKey",
                table: "MediaResources",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PreviewKey",
                table: "MediaResources");
        }
    }
}
