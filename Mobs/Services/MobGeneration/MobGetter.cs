using System.Collections.Generic;
using System.Linq;
using CharacterDemo.General;
using Godot;

namespace CharacterDemo.Mobs.Services.MobGeneration;

public static class MobGetter
{

    public static int GetMainMaterial(MeshInstance3D meshInstance)
    {
        if (meshInstance.Name == "Eyes") return 1;
        if (meshInstance.Name == "Top") return 1;
        if (meshInstance.Name == "Bottom") return 1;
        return 0;
    }

    public static MeshInstance3D? GetMeshFromSkeleton(string meshName, Skeleton3D skeleton)
    {
        if (MobConstants.HandNames[0] == meshName)
            return skeleton.GetNode<Node3D>("Hip").GetChild(0).GetChild<MeshInstance3D>(0);
        return MobConstants.HandNames[1] == meshName
            ? skeleton.GetNode<Node3D>("Back").GetChild(0).GetChild<MeshInstance3D>(0)
            : skeleton.GetNodeOrNull<MeshInstance3D>(meshName);
    }

    public static IReadOnlyList<string> GetShapeNamesFromMesh(Mesh? mesh)
    {
        if (mesh is not ArrayMesh arrayMesh) return [];
        var path = arrayMesh.ResourcePath;
        if (GeneralConstants.CachedMeshShapeNames.TryGetValue(path, out var names)) return names;
        names = Enumerable
            .Range(0, arrayMesh.GetBlendShapeCount())
            .Select(i => arrayMesh.GetBlendShapeName(i).ToString())
            .ToList();
        GeneralConstants.CachedMeshShapeNames[path] = names;
        return names;
    }
    
}
