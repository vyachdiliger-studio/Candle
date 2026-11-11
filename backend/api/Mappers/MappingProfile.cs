using AutoMapper;
using CandleBackend.Dtos;
using CandleBackend.Models;
using CandleBackend.Routing;

namespace CandleBackend.Mappers;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<Candle, CandleResponse>()
            .ForCtorParam(nameof(CandleResponse.SupportersCount), o => o.MapFrom(_ => 0))
            .ForCtorParam(nameof(CandleResponse.CommentsCount), o => o.MapFrom(_ => 0))
            .ForCtorParam(
                nameof(CandleResponse.Background),
                o => o.MapFrom(c => c.BackgroundResource != null && c.BackgroundResource.ReadyAt != null ? c.BackgroundResource : null)
            )
            .ForCtorParam(
                nameof(CandleResponse.Location),
                o => o.MapFrom(c => c.Location == null
                    ? null
                    : new LocationDto(c.Location.Y, c.Location.X))
            )
            .ForCtorParam(
                nameof(CandleResponse.Author),
                o => o.MapFrom(c => c.User)
            );

        CreateMap<User, UserResponse>().ForCtorParam(nameof(UserResponse.HasPassword),
            o => o.MapFrom(u => u.UserLogins.Any(l => l.Provider == AuthProviderType.UsernamePassword)));

        CreateMap<MediaResource, ResourceResponse>()
            .ForCtorParam(nameof(ResourceResponse.Url),
                o => o.MapFrom(r => $"{ApiRoutes.Prefix}/resources/{r.Id}/content"))
            .ForCtorParam(nameof(ResourceResponse.ThumbnailUrl),
                o => o.MapFrom(r => $"{ApiRoutes.Prefix}/resources/{r.Id}/thumbnail"));

        CreateMap<User, CandleAuthorDto>();
    }
}
