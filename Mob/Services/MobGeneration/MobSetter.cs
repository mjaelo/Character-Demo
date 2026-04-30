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
        MobAdjuster.AdjustMobToRace(mob, mobData.Race);
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

        if (!string.IsNullOrEmpty(meshData.MeshFile))
        {
            if (!string.IsNullOrEmpty(meshInfo.FileFolder)) MobUtils.SetMesh(meshData.MeshFile, meshInstance, meshInfo.FileFolder);
            else if (meshData.MeshFile == "empty") meshInstance.Hide();
            else meshInstance.Show();
        }

        if (meshData.MeshColor != new Color())
        {
            int materialNr = meshName == "Body" ? 0 : -1;
            MobUtils.SetMeshColor(meshData.MeshColor, meshInstance, materialNr);
        }

        if (meshData.MeshShapes.Count > 0)
        {
            var shapeNames = MobUtils.GetShapeNamesFromMesh(meshInstance.Mesh);
            if (meshData.MeshShapes.Count != shapeNames.Count)
            {
                GD.Print(meshName + " shapes differ in saved data and mesh");
                return;
            }
            var skeleton = (Skeleton3D)meshInstance.GetParent();
            for (int i = 0; i < meshData.MeshShapes.Count; i++)
                MobUtils.SetSkeletonShapeKey(meshData.MeshShapes[i], shapeNames[i], skeleton);
        }
    }
}

