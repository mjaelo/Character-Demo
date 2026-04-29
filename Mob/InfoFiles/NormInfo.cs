using System.Collections.Generic;
using Godot;
using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.InfoFiles;

/// Encodes one norm rule used during mob generation/adjustment.
/// Forbidden=false → the value is mandatory (must match).
/// Forbidden=true  → the value is forbidden (must NOT match).
/// Enforce=true    → this norm is always applied (ignores variation_chance).
public class NormInfo(
    bool forbidden = false,
    bool enforce = false,
    IReadOnlyList<string>? tags = null,
    IReadOnlyDictionary<string, string>? meshes = null,
    IReadOnlyDictionary<string, IReadOnlyList<Color>>? colors = null,
    IReadOnlyDictionary<string, IReadOnlyDictionary<int, float[]>>? shapes = null
)
{
    public readonly bool Forbidden = forbidden;
    public readonly bool Enforce = enforce;

    public IReadOnlyList<string> Tags = tags ?? System.Array.Empty<string>();
    public IReadOnlyDictionary<string, string> Meshes = meshes ?? new Dictionary<string, string>();
    public IReadOnlyDictionary<string, IReadOnlyList<Color>> Colors = colors ?? new Dictionary<string, IReadOnlyList<Color>>();
    public IReadOnlyDictionary<string, IReadOnlyDictionary<int, float[]>> Shapes = shapes ?? new Dictionary<string, IReadOnlyDictionary<int, float[]>>();
}