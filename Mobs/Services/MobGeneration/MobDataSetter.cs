using System;
using System.Linq;
using CharacterDemo.Mobs.DataFiles;
using CharacterDemo.Mobs.Scenes.MobScene;
using Godot;

namespace CharacterDemo.Mobs.Services.MobGeneration;

public static class MobDataSetter
{
    public static void SetMobDataToMob(MobData mobData, Mob mob)
    {
        mob.MobName = mobData.MobName;
        mob.Race = mobData.Race;
        mob.Type = mobData.Type;
        mob.Gender = mobData.Gender;
        mob.EquipmentData = mobData.EquipmentData;
        mob.BodyData = mobData.BodyData;
        // Adjust Race Extra Features
        mob.Scale = Vector3.One * mobData.Race switch { MobEnums.MobRaces.Spirit => MobConstants.SpiritScale, MobEnums.MobRaces.Ogre => MobConstants.OgreScale, _ => 1 };
        SetBodyData(mobData.BodyData, mob);
        SetEquipmentData(mobData.EquipmentData, mob);
    }

    public static void SetBodyData(BodyData bodyData, Mob mob)
    {
        mob.BodyData = bodyData;
        var skeleton = mob.GetNode<Skeleton3D>("body/Armature/Skeleton3D");
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var meshData = MobDataGetter.GetBodyDataFieldValue(bodyData, meshInfo.FieldName);
            var meshInstance = MobGetter.GetMeshFromSkeleton(meshName, skeleton);
            if (meshInstance != null) SetMeshData(meshData, meshName, meshInstance);
        }
        // Propagate skin color from Head to other meshes with skin
        if (bodyData.HeadMesh.MeshColors.Count > 0)
            MobUtils.PropagateSkinColorData(mob.EquipmentData, bodyData.HeadMesh.MeshColors[0], skeleton);
    }

    public static void SetEquipmentData(EquipmentData eqData, Mob mob)
    {
        mob.EquipmentData = eqData;
        var skeleton = mob.GetNode<Skeleton3D>("body/Armature/Skeleton3D");
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var meshData = MobDataGetter.GetEqDataFieldValue(eqData, meshInfo.FieldName);
            var meshInstance = MobGetter.GetMeshFromSkeleton(meshName, skeleton);
            if (meshInstance != null) SetMeshData(meshData, meshName, meshInstance);
        }
    }

    private static void SetMeshData(MeshData meshData, string meshName, MeshInstance3D meshInstance)
    {
        bool isBody = MobConstants.BodyMeshesInfo.ContainsKey(meshName);
        var meshInfo = isBody ? MobConstants.BodyMeshesInfo[meshName] : MobConstants.EqMeshesInfo[meshName];

        MobSetter.SetMeshFile(meshData.MeshFile, meshInstance, meshInfo.FileFolder);
        
        if (!MobConstants.ShapelessFiles.Contains(meshData.MeshFile) && meshData.MeshShapes.Count > 0 && meshInfo.Shapes.Count > 0)
        {
            var shapeNames = MobGetter.GetShapeNamesFromMesh(meshInstance.Mesh);
            int count = Math.Min(meshData.MeshShapes.Count, shapeNames.Count);
            if (meshData.MeshShapes.Count != shapeNames.Count)
                GD.Print(meshName + " shapes differ in meshData and mesh ",string.Join(", ", meshData.MeshShapes), " vs ", string.Join(", ", shapeNames));
            var skeleton = (Skeleton3D)meshInstance.GetParent();
            for (int i = 0; i < count; i++)
                MobSetter.SetSkeletonShapeKey(meshData.MeshShapes[i], shapeNames[i], skeleton);
        }

        for (int i = 0; i < meshData.MeshColors.Count; i++)
        {
            var color = meshData.MeshColors[i];
            if (color == new Color()) continue;
            MobSetter.SetMeshColor(color, meshInstance, i);
        }
    }
    
    // Field Accessors
    public static void SetDataToBodyDataField(BodyData bodyData, string fieldName, MeshData meshData)
    {
        switch (fieldName)
        {
            case "HeadMesh": bodyData.HeadMesh = meshData; break;
            case "EyeMesh": bodyData.EyeMesh = meshData; break;
            case "LashesMesh": bodyData.LashesMesh = meshData; break;
            case "HairMesh": bodyData.HairMesh = meshData; break;
            case "BeardMesh": bodyData.BeardMesh = meshData; break;
            case "BrowMesh": bodyData.BrowMesh = meshData; break;
        }
    }

    public static void SetDataToEqDataField(EquipmentData eqData, string fieldName, MeshData meshData)
    {
        switch (fieldName)
        {
            case "TopMesh": eqData.TopMesh = meshData; break;
            case "BottomMesh": eqData.BottomMesh = meshData; break;
            case "ShoeMesh": eqData.ShoeMesh = meshData; break;
            case "HatMesh": eqData.HatMesh = meshData; break;
            case "RHandMesh": eqData.RHandMesh = meshData; break;
            case "LHandMesh": eqData.LHandMesh = meshData; break;
            case "AccessoryMesh": eqData.AccessoryMesh = meshData; break;
        }
    }
}