using System;
using System.Linq;
using CharacterDemo.Mob.DataFiles;
using Godot;

namespace CharacterDemo.Mob.Services.MobGeneration;

public static class MobSetter
{
    public static void SetMobDataToMob(MobData mobData, Scenes.Mob.Mob mob)
    {
        mob.MobName = mobData.MobName;
        mob.Race = mobData.Race;
        mob.Type = mobData.Type;
        mob.Gender = mobData.Gender;
        mob.EquipmentData = mobData.EquipmentData;
        mob.BodyData = mobData.BodyData;
        MobAdjuster.AdjustRaceExtraFeatures(mob, mobData.Race);
        SetBodyData(mobData.BodyData, mob);
        SetEquipmentData(mobData.EquipmentData, mob);
    }

    public static void SetBodyData(BodyData bodyData, Scenes.Mob.Mob mob)
    {
        mob.BodyData = bodyData;
        var skeleton = mob.GetNode<Skeleton3D>("body/Armature/Skeleton3D");
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var meshData = MobUtils.GetBodyDataFieldValue(bodyData, meshInfo.FieldName);
            var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
            if (meshInstance != null) SetMeshData(meshData, meshName, meshInstance);
        }
        // Propagate skin color from Head to other meshes with skin
        if (bodyData.HeadMesh.MeshColors.Count > 0)
            MobUtils.PropagateSkinColorData(mob.EquipmentData, bodyData.HeadMesh.MeshColors[0], skeleton);
    }

    public static void SetEquipmentData(EquipmentData eqData, Scenes.Mob.Mob mob)
    {
        mob.EquipmentData = eqData;
        var skeleton = mob.GetNode<Skeleton3D>("body/Armature/Skeleton3D");
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var meshData = MobUtils.GetEqDataFieldValue(eqData, meshInfo.FieldName);
            var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
            if (meshInstance != null) SetMeshData(meshData, meshName, meshInstance);
        }
    }

    private static void SetMeshData(MeshData meshData, string meshName, MeshInstance3D meshInstance)
    {
        bool isBody = MobConstants.BodyMeshesInfo.ContainsKey(meshName);
        var meshInfo = isBody ? MobConstants.BodyMeshesInfo[meshName] : MobConstants.EqMeshesInfo[meshName];

        MobUtils.SetMeshFile(meshData.MeshFile, meshInstance, meshInfo.FileFolder);
        
        if (!MobConstants.ShapelessFiles.Contains(meshData.MeshFile) && meshData.MeshShapes.Count > 0 && meshInfo.Shapes.Count > 0)
        {
            var shapeNames = MobUtils.GetShapeNamesFromMesh(meshInstance.Mesh);
            int count = Math.Min(meshData.MeshShapes.Count, shapeNames.Count);
            if (meshData.MeshShapes.Count != shapeNames.Count)
                GD.Print(meshName + " shapes differ in meshData and mesh ",string.Join(", ", meshData.MeshShapes), " vs ", string.Join(", ", shapeNames));
            var skeleton = (Skeleton3D)meshInstance.GetParent();
            for (int i = 0; i < count; i++)
                MobUtils.SetSkeletonShapeKey(meshData.MeshShapes[i], shapeNames[i], skeleton);
        }

        for (int i = 0; i < meshData.MeshColors.Count; i++)
        {
            var color = meshData.MeshColors[i];
            if (color == new Color()) continue;
            MobUtils.SetMeshColor(color, meshInstance, i);
        }
    }
}