using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.DataFiles;

/// Holds the selected mesh file, color and shape key values for one mesh slot.
public class MeshData(IReadOnlyList<Color>? meshColors = null, string meshFile = "", IReadOnlyList<float>? meshShapes = null)
{
    public IReadOnlyList<Color> MeshColors = meshColors ?? [];
    public string MeshFile = meshFile;
    public IReadOnlyList<float> MeshShapes = meshShapes ?? [];
}