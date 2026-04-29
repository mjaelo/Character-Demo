using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.DataFiles;

/// Holds the selected mesh file, color and shape key values for one mesh slot.
public class MeshData(Color meshColor = new(), string meshFile = "", List<float>? meshShape = null)
{
    public Color MeshColor = meshColor;
    public string MeshFile = meshFile;
    public List<float> MeshShape = meshShape ?? []; // is edited by pickers
}