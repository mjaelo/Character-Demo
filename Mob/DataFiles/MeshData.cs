using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.DataFiles;

/// Holds the selected mesh file, color and shape key values for one mesh slot.
public class MeshData(Color meshColor = new(), string meshFile = "", IReadOnlyList<float>? meshShape = null)
{
    public Color MeshColor = meshColor;
    public string MeshFile = meshFile;
    public IReadOnlyList<float> MeshShapes = meshShape ?? []; // is edited by pickers
}