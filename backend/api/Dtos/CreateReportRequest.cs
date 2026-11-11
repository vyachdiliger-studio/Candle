using System.ComponentModel.DataAnnotations;
using CandleBackend.Models;

namespace CandleBackend.Dtos;

public sealed record CreateReportRequest(
    [EnumDataType(typeof(ReportReason))] ReportReason Reason,
    long? CandleId = null,
    long? UserId = null,
    [MaxLength(2000)] string? Details = null,
    long? CommentId = null
);
