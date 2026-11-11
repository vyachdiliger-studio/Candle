using System.Security.Claims;

namespace CandleBackend.Extensions;

public static class ClaimsPrincipalExtensions
{
    public static long GetId(this ClaimsPrincipal user)
    {
        var id = user.FindFirstValue("id");

        if (id is null)
            throw new InvalidOperationException("User id claim is missing");

        return long.Parse(id);
    }
}
