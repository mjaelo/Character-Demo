using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.DataFiles;

/// Holds the selected mesh file, color and shape key values for one mesh slot.
public class MeshData(IReadOnlyList<Color>? meshColor = null, string meshFile = "", IReadOnlyList<float>? meshShape = null)
{
    public IReadOnlyList<Color> MeshColors = meshColor ?? [];
    public string MeshFile = meshFile;
    public IReadOnlyList<float> MeshShapes = meshShape ?? [];
}