using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.InfoFiles;

/// Describes the asset folder, valid colors and valid shape ranges for one mesh slot.
public class MobMeshInfo(
    string fieldName,
    string fileFolder,
    IReadOnlyList<Color>? colors = null,
    IReadOnlyList<MobShapeInfo>? shapes = null)
{
    public readonly string FieldName = fieldName;
    public readonly string FileFolder = fileFolder;
    public readonly IReadOnlyList<Color> Colors = colors ?? new List<Color>();
    public readonly IReadOnlyList<MobShapeInfo> Shapes = shapes ?? new List<MobShapeInfo>();
}

