using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Text.Json;
using System.Text.Json.Serialization;
using CharacterDemo.Mob;
using Godot;

namespace CharacterDemo.General.Services;

public static class SerializationService
{
    private static readonly JsonSerializerOptions SerializeOptions = new()
    {
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        IncludeFields = true,
        PropertyNameCaseInsensitive = true,
        Converters = { new JsonStringEnumConverter(), new ColorListConverter(), new ColorConverter(), new Vector2Converter() }
    };
    
    public static string Serialize<T>(T obj) => JsonSerializer.Serialize(obj, SerializeOptions);

    public static T? Deserialize<T>(string json) => JsonSerializer.Deserialize<T>(json, SerializeOptions);

    private class Vector2Converter : JsonConverter<Vector2>
    {
        public override Vector2 Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            using var doc = JsonDocument.ParseValue(ref reader);
            var arr = doc.RootElement.EnumerateArray().Select(x => x.GetSingle()).ToList();
            return new Vector2(arr[0], arr[1]);
        }
        public override void Write(Utf8JsonWriter writer, Vector2 value, JsonSerializerOptions options)
        {
            writer.WriteStartArray();
            writer.WriteNumberValue(value.X);
            writer.WriteNumberValue(value.Y);
            writer.WriteEndArray();
        }
    }

    private class ColorConverter : JsonConverter<Color>
    {
        public override Color Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            using var doc = JsonDocument.ParseValue(ref reader);
            var arr = doc.RootElement.EnumerateArray().Select(x => x.GetSingle()).ToList();
            return new Color(arr[0], arr[1], arr[2], arr.Count > 3 ? arr[3] : 1f);
        }
        public override void Write(Utf8JsonWriter writer, Color value, JsonSerializerOptions options)
        {
            writer.WriteStartArray();
            writer.WriteNumberValue(value.R);
            writer.WriteNumberValue(value.G);
            writer.WriteNumberValue(value.B);
            writer.WriteNumberValue(value.A);
            writer.WriteEndArray();
        }
    }

    private class ColorListConverter : JsonConverter<IReadOnlyList<Color>>
    {
        public override IReadOnlyList<Color> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
        {
            using var doc = JsonDocument.ParseValue(ref reader);
            var result = new List<Color>();
            foreach (var item in doc.RootElement.EnumerateArray())
            {
                var name = item.GetString()!;
                var field = typeof(MobConstants).GetField(name, BindingFlags.Public | BindingFlags.Static);
                if (field?.GetValue(null) is IReadOnlyList<Color> colors)
                    result.AddRange(colors);
            }
            return result;
        }

        public override void Write(Utf8JsonWriter writer, IReadOnlyList<Color> value, JsonSerializerOptions options)
        {
            writer.WriteStartArray();
            foreach (var c in value)
            {
                writer.WriteStartArray();
                writer.WriteNumberValue(c.R);
                writer.WriteNumberValue(c.G);
                writer.WriteNumberValue(c.B);
                writer.WriteNumberValue(c.A);
                writer.WriteEndArray();
            }
            writer.WriteEndArray();
        }
    }
}
