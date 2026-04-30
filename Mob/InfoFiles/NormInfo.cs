using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.InfoFiles;

/// Encodes one norm rule used during mob generation/adjustment.
/// Forbidden whether value is forbidden or mandatory
/// Enforce    whether this norm is always applied (ignores variation_chance).
public class NormInfo(
    bool forbidden = false,
    bool enforce = false,
    IReadOnlyList<string>? meshNames = null,
    IReadOnlyList<string>? tags = null, // possible tags for any mesh
    IReadOnlyList<string>? files = null, // possible file names for meshName
    IReadOnlyList<Color>? colors = null, // possible colors for meshName
    IReadOnlyDictionary<int, float[]>? shapes = null // possible shape values for meshName
)
{
    public bool Forbidden = forbidden;
    public bool Enforce = enforce;
    public IReadOnlyList<string> MeshNames = meshNames ?? [];
    public IReadOnlyList<string> Tags = tags ?? [];
    public IReadOnlyList<string> Files = files ?? [];
    public IReadOnlyList<Color> Colors = colors ?? [];
    public IReadOnlyDictionary<int, float[]> Shapes = shapes ?? new Dictionary<int, float[]>();
}