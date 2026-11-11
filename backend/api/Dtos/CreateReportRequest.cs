using System.ComponentModel.DataAnnotations;
using CandleBackend.Models;

namespace CandleBackend.Dtos;

public sealed record CreateReportRequest(
    [property: EnumDataType(typeof(ReportReason))] ReportReason Reason,
    long? CandleId = null,
    long? UserId = null,
    [property: MaxLength(2000)] string? Details = null
);
