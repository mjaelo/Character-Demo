using System.Collections.Generic;
using System.Linq;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.InfoFiles;
using Godot;
using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.Services.MobGeneration;

///  ADJUST (keep valid, re-randomize invalid) 
public static class MobAdjuster
{
    // adjust non editable parameters, f.e. scale, colors, visibility TODO export colors and skel body meshes and leave only mob scale & AlbedoTextureMsdf
    public static void AdjustRaceExtraFeatures(Scenes.Mob.Mob mob, MobRaces race) // TODO store values externally? f.e. json, in norms
    {
        var skeleton = mob.GetNode<Skeleton3D>("body/Armature/Skeleton3D");
        // mob scale
        mob.Scale = Vector3.One * race switch { MobRaces.Spirit => MobConstants.SpiritScale, MobRaces.Ogre => MobConstants.OgreScale, _ => 1 };

        // setting AlbedoTextureMsdf for top? TODO idk what that does.
        var topMesh = skeleton.GetNode<MeshInstance3D>("Top");
        var material = (StandardMaterial3D?)topMesh.GetActiveMaterial(0);
        if (material != null)
            material.AlbedoTextureMsdf = race is MobRaces.Statue or MobRaces.Spirit;
    }
    
    public static BodyData AdjustBodyData(List<NormInfo> norms, BodyData bodyData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var meshNorms = norms.Where(norm => !norm.MeshNames.Any() || norm.MeshNames.Contains(meshName) || norm.MeshNames.Contains("BodyBulk")).ToList();
            var current = MobUtils.GetBodyDataFieldValue(bodyData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, meshInfo, meshNorms, current);
            MobUtils.SetDataToBodyDataField(bodyData, meshInfo.FieldName, adjusted);
        }
        MobUtils.PropagateHairColor(bodyData);
        return bodyData;
    }
    public static EquipmentData AdjustEquipmentData(List<NormInfo> norms, EquipmentData eqData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var meshNorms = norms.Where(norm => !norm.MeshNames.Any() || norm.MeshNames.Contains(meshName) || norm.MeshNames.Contains("EquipmentBulk")).ToList();
            var current = MobUtils.GetEqDataFieldValue(eqData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, meshInfo, meshNorms, current);
            MobUtils.SetDataToEqDataField(eqData, meshInfo.FieldName, adjusted);
        }
        return eqData;
    }
    private static MeshData AdjustMeshData(string meshName, MobMeshInfo meshInfo, List<NormInfo> norms, MeshData meshData)
    {
        meshData.MeshFile = MobGetter.GetRandomMeshFile(meshName, norms, meshInfo.FileFolder, meshData.MeshFile);
        meshData.MeshColors = MobGetter.GetRandomMeshColor(norms, meshInfo, meshData.MeshColors);
        meshData.MeshShapes = MobGetter.GetRandomMeshShapes(norms, meshInfo.Shapes, meshData.MeshShapes);
        return meshData;
    }

}

