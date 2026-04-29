using Godot;

namespace CharacterDemo.Mob.InfoFiles;
// TODO dont use ColorRangeInfo object at all

/// Describes the valid color range (hue/saturation/brightness/alpha) for a mesh.
public record ColorRangeInfo(
    Vector2 Hue,
    Vector2 Saturation,
    Vector2 Brightness,
    Vector2 Alpha
)
{
    public ColorRangeInfo(
        Vector2? hue = null,
        Vector2? saturation = null,
        Vector2? brightness = null,
        Vector2? alpha = null
    ) : this(
        hue ?? Vector2.Zero,
        saturation ?? Vector2.Zero,
        brightness ?? Vector2.Zero,
        alpha ?? Vector2.One
    ) { }
}

