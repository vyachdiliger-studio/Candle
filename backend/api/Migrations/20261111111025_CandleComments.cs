using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace CandleBackend.Migrations
{
    /// <inheritdoc />
    public partial class CandleComments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "CommentId",
                table: "ContentReports",
                type: "bigint",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "CandleComments",
                columns: table => new
                {
                    Id = table.Column<long>(type: "bigint", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    CandleId = table.Column<long>(type: "bigint", nullable: false),
                    UserId = table.Column<long>(type: "bigint", nullable: false),
                    ParentCommentId = table.Column<long>(type: "bigint", nullable: true),
                    RootCommentId = table.Column<long>(type: "bigint", nullable: true),
                    Path = table.Column<string>(type: "character varying(4000)", maxLength: 4000, nullable: false),
                    Depth = table.Column<int>(type: "integer", nullable: false),
                    Text = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CandleComments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_CandleComments_CandleComments_ParentCommentId",
                        column: x => x.ParentCommentId,
                        principalTable: "CandleComments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_CandleComments_CandleComments_RootCommentId",
                        column: x => x.RootCommentId,
                        principalTable: "CandleComments",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_CandleComments_Candles_CandleId",
                        column: x => x.CandleId,
                        principalTable: "Candles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_CandleComments_Users_UserId",
                        column: x => x.UserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ContentReports_CommentId",
                table: "ContentReports",
                column: "CommentId");

            migrationBuilder.CreateIndex(
                name: "IX_CandleComments_CandleId_ParentCommentId_CreatedAt_Id",
                table: "CandleComments",
                columns: new[] { "CandleId", "ParentCommentId", "CreatedAt", "Id" });

            migrationBuilder.CreateIndex(
                name: "IX_CandleComments_CandleId_Path",
                table: "CandleComments",
                columns: new[] { "CandleId", "Path" });

            migrationBuilder.CreateIndex(
                name: "IX_CandleComments_ParentCommentId",
                table: "CandleComments",
                column: "ParentCommentId");

            migrationBuilder.CreateIndex(
                name: "IX_CandleComments_RootCommentId",
                table: "CandleComments",
                column: "RootCommentId");

            migrationBuilder.CreateIndex(
                name: "IX_CandleComments_UserId",
                table: "CandleComments",
                column: "UserId");

            migrationBuilder.AddForeignKey(
                name: "FK_ContentReports_CandleComments_CommentId",
                table: "ContentReports",
                column: "CommentId",
                principalTable: "CandleComments",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ContentReports_CandleComments_CommentId",
                table: "ContentReports");

            migrationBuilder.DropTable(
                name: "CandleComments");

            migrationBuilder.DropIndex(
                name: "IX_ContentReports_CommentId",
                table: "ContentReports");

            migrationBuilder.DropColumn(
                name: "CommentId",
                table: "ContentReports");
        }
    }
}
