using System.Text.Json;
using System.Text.Json.Serialization;

namespace CandleBackend.Json;

/// <summary>
/// A field of a partial update, able to tell "not sent" from "sent as null".
///
/// System.Text.Json only invokes a converter for keys actually present in the
/// body, so an omitted property keeps the default <see cref="IsUndefined"/>.
/// That distinction is the whole point: PATCH must leave absent fields alone,
/// while an explicit null clears the value.
///
/// DotNext ships an equivalent, but it exposes a byref member that MVC's
/// metadata provider cannot reflect over, so binding it from a request body
/// throws before the action runs.
/// </summary>
[JsonConverter(typeof(OptionalJsonConverterFactory))]
public readonly struct Optional<T>
{
    public Optional(T? value)
    {
        IsDefined = true;
        ValueOrDefault = value;
    }

    public bool IsDefined { get; }

    public bool IsUndefined => !IsDefined;

    public bool IsNull => IsDefined && ValueOrDefault is null;

    public bool HasValue => IsDefined && ValueOrDefault is not null;

    public T? ValueOrDefault { get; }
}

public sealed class OptionalJsonConverterFactory : JsonConverterFactory
{
    public override bool CanConvert(Type type) =>
        type.IsGenericType && type.GetGenericTypeDefinition() == typeof(Optional<>);

    public override JsonConverter CreateConverter(Type type, JsonSerializerOptions options) =>
        (JsonConverter)Activator.CreateInstance(
            typeof(OptionalJsonConverter<>).MakeGenericType(type.GetGenericArguments()[0]))!;
}

public sealed class OptionalJsonConverter<T> : JsonConverter<Optional<T>>
{
    public override Optional<T> Read(ref Utf8JsonReader reader, Type type, JsonSerializerOptions options) =>
        new(JsonSerializer.Deserialize<T>(ref reader, options));

    public override void Write(Utf8JsonWriter writer, Optional<T> value, JsonSerializerOptions options)
    {
        if (value.IsUndefined)
        {
            writer.WriteNullValue();

            return;
        }

        JsonSerializer.Serialize(writer, value.ValueOrDefault, options);
    }
}
