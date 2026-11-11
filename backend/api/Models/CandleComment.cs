using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Microsoft.EntityFrameworkCore;

namespace CandleBackend.Models;

/// <summary>
/// A comment in a candle's thread. Replies form a tree: <see cref="ParentCommentId"/>
/// is the comment answered, <see cref="RootCommentId"/> the top-level comment of the
/// branch. <see cref="Path"/> lists the ids of all ancestors (<c>/12/45/</c>, <c>/</c>
/// for a top-level comment), so a whole subtree is one prefix match.
/// </summary>
[Index(nameof(CandleId), nameof(ParentCommentId), nameof(CreatedAt), nameof(Id))]
[Index(nameof(CandleId), nameof(Path))]
[Index(nameof(UserId))]
public sealed class CandleComment
{
    public const int TextMaxLength = 1000;
    public const int PathMaxLength = 4000;

    public long Id { get; set; }

    public long CandleId { get; set; }
    public Candle Candle { get; set; } = null!;

    public long UserId { get; set; }
    public User User { get; set; } = null!;

    public long? ParentCommentId { get; set; }
    public CandleComment? ParentComment { get; set; }

    public long? RootCommentId { get; set; }
    public CandleComment? RootComment { get; set; }

    [MaxLength(PathMaxLength)]
    public string Path { get; set; } = "/";

    /// <summary>0 for a top-level comment, 1 for a reply to it, and so on.</summary>
    public int Depth { get; set; }

    [MaxLength(TextMaxLength)]
    public string Text { get; set; } = "";

    public DateTime CreatedAt { get; set; }

    /// <summary>Soft delete. The text stays in the database but is never returned.</summary>
    public DateTime? DeletedAt { get; set; }

    /// <summary>The prefix shared by <see cref="Path"/> of every descendant.</summary>
    [NotMapped]
    public string DescendantPath => $"{Path}{Id}/";
}
