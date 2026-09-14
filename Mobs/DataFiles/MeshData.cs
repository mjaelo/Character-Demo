using System.Collections.Generic;
using System.Linq;
using Godot;

namespace CharacterDemo.Mobs.DataFiles;

/// Holds the selected mesh file, color and shape key values for one mesh slot.
public record MeshData
{
    public IReadOnlyList<Color> MeshColors = [];
    public string MeshFile = "";
    public IReadOnlyList<float> MeshShapes = [];

    public MeshData Duplicate() => new MeshData
        { MeshColors = MeshColors.ToList(), MeshFile = MeshFile, MeshShapes = MeshShapes.ToList() };
}