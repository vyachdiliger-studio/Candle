# Build context: ./backend (the API references the bot project next to it).
FROM mcr.microsoft.com/dotnet/sdk:10.0.402 AS base

WORKDIR /src

COPY api/CandleBackend.csproj api/
COPY bot/CandleBot.csproj bot/
RUN dotnet restore api/CandleBackend.csproj

COPY . .


FROM base AS dev

ENV ASPNETCORE_URLS=http://0.0.0.0:8080
ENV DOTNET_USE_POLLING_FILE_WATCHER=1
ENV DOTNET_WATCH_RESTART_ON_RUDE_EDIT=1

EXPOSE 8080

CMD ["dotnet", "watch", "--project", "api/CandleBackend.csproj", "run", "--no-launch-profile", "--non-interactive"]


FROM base AS publish

RUN dotnet publish api/CandleBackend.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    /p:UseAppHost=false


FROM mcr.microsoft.com/dotnet/aspnet:10.0.13 AS prod

# Npgsql probes GSSAPI on connect and logs an error without this library.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgssapi-krb5-2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=publish /app/publish .

ENV ASPNETCORE_URLS=http://0.0.0.0:8080

USER $APP_UID

EXPOSE 8080

ENTRYPOINT ["dotnet", "CandleBackend.dll"]
