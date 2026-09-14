using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mobs.InfoFiles;

/// Encodes one norm rule used during mob generation/adjustment. Fields cant be readonly, as it would break MobConstants.LoadNorms logic.
/// 
/// Forbidden whether value is forbidden or mandatory
/// Enforce   whether this norm is always applied (ignores variation_chance).
/// MeshNames list of mesh names this norm applies to.
/// Tags      possible tags for any mesh
/// Files     possible file names for meshName
/// Colors    possible colors per material index for meshName
/// Shapes    possible shape values for meshName
public class NormInfo
{
    public bool Forbidden = false;
    public bool Enforce = false;
    public IReadOnlyList<string> MeshNames = [];
    public IReadOnlyList<string> Tags = [];
    public IReadOnlyList<string> Files = [];
    public IReadOnlyDictionary<int, List<Color>> Colors = new Dictionary<int, List<Color>>();
    public IReadOnlyDictionary<int, float[]> Shapes = new Dictionary<int, float[]>();
}