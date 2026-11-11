using Microsoft.OpenApi;
using Swashbuckle.AspNetCore.SwaggerGen;

namespace CandleBackend.Json;

/// <summary>
/// <see cref="Optional{T}"/> is a wrapper only in C#; on the wire it is just T,
/// present or absent. Without this the generated document would advertise
/// <c>{ hasValue, value }</c> and every client built from it would be wrong.
/// </summary>
public sealed class OptionalSchemaFilter : ISchemaFilter
{
    public void Apply(IOpenApiSchema schema, SchemaFilterContext context)
    {
        if (schema is not OpenApiSchema target) return;

        if (target.Properties is null || target.Properties.Count == 0) return;

        foreach (var property in context.Type.GetProperties())
        {
            var type = property.PropertyType;

            if (!type.IsGenericType || type.GetGenericTypeDefinition() != typeof(Optional<>)) continue;

            var key = target.Properties.Keys.FirstOrDefault(
                it => string.Equals(it, property.Name, StringComparison.OrdinalIgnoreCase));

            if (key is null) continue;

            target.Properties[key] = AllowNull(context.SchemaGenerator.GenerateSchema(
                type.GetGenericArguments()[0],
                context.SchemaRepository));
        }
    }

    /// <summary>
    /// An explicit null is how a patch clears a field, so the document has to
    /// permit it - otherwise generated clients can only ever set a value.
    /// </summary>
    private static IOpenApiSchema AllowNull(IOpenApiSchema schema)
    {
        if (schema is OpenApiSchema plain && plain.Type is { } kind)
        {
            plain.Type = kind | JsonSchemaType.Null;

            return plain;
        }

        // A bare $ref carries no keywords of its own, so the null has to sit on
        // a wrapper around it rather than on the reference.
        return new OpenApiSchema { Type = JsonSchemaType.Null, AllOf = [schema] };
    }
}
