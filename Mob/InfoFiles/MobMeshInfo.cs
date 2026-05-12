using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.InfoFiles;

/// Describes the asset folder, valid colors and valid shape ranges for one mesh slot.
public class MobMeshInfo(
    string fieldName,
    string fileFolder,
    IReadOnlyDictionary<int, IReadOnlyList<Color>>? colors = null,
    IReadOnlyList<MobShapeInfo>? shapes = null)
{
    public readonly string FieldName = fieldName;
    public readonly string FileFolder = fileFolder;
    public readonly IReadOnlyDictionary<int, IReadOnlyList<Color>> Colors = colors ?? new Dictionary<int, IReadOnlyList<Color>>();
    public readonly IReadOnlyList<MobShapeInfo> Shapes = shapes ?? new List<MobShapeInfo>();
}

