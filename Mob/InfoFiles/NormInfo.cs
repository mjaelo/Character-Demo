using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.InfoFiles;

/// Encodes one norm rule used during mob generation/adjustment.
/// Forbidden whether value is forbidden or mandatory
/// Enforce    whether this norm is always applied (ignores variation_chance).
public class NormInfo
{
    public bool Forbidden;
    public bool Enforce;
    public IReadOnlyList<string> MeshNames = [];
    public IReadOnlyList<string> Tags = []; // possible tags for any mesh
    public IReadOnlyList<string> Files = []; // possible file names for meshName
    public IReadOnlyDictionary<int, List<Color>> Colors = new Dictionary<int, List<Color>>(); // possible colors per material index for meshName
    public IReadOnlyDictionary<int, float[]> Shapes = new Dictionary<int, float[]>(); // possible shape values for meshName
}