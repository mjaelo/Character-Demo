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

        // show monster body, hide normal body TODO should be done by norms, monster body as body file name. (new skeleton bottom & top meshes?)
        bool showMonsterBody = race == MobRaces.Skeleton;
        foreach (var child in skeleton.GetChildren().OfType<MeshInstance3D>())
        {
            if (MobConstants.HandNames.Contains(child.Name.ToString()) ||
                (!MobConstants.BodyMeshesInfo.Keys.Contains(child.Name.ToString()) &&
                 !MobConstants.EqMeshesInfo.Keys.Contains(child.Name.ToString())))
                continue;
            child.Visible = showMonsterBody == (child.Name == "monster-body");
        }

        // mob scale
        mob.Scale = Vector3.One * race switch { MobRaces.Spirit => MobConstants.SpiritScale, MobRaces.Ogre => MobConstants.OgreScale, _ => 1 };

        // setting AlbedoTextureMsdf for top? TODO idk what that does.
        var topMesh = skeleton.GetNode<MeshInstance3D>("Top");
        var material = (StandardMaterial3D?)topMesh.GetActiveMaterial(0);
        if (material != null)
            material.AlbedoTextureMsdf = race is MobRaces.Statue or MobRaces.Spirit;

        // eye secondary colors TODO keep all colors in MeshData? add to norms?
        var eyesMesh = skeleton.GetNode<MeshInstance3D>("Eyes");
        var eyePupilColor =  race switch
        {
            MobRaces.Statue => MobConstants.ColorStatueGrey,
            MobRaces.Spirit => MobConstants.SpiritEyeWhitesColor,
            _ => Colors.Black
        };
        MobUtils.SetMeshColor(eyePupilColor, eyesMesh, 2);
        
        var eyeWhiteColor = race switch
        {
            MobRaces.Statue => MobConstants.ColorStatueGrey, 
            MobRaces.Spirit => MobConstants.SpiritEyeWhitesColor,
            MobRaces.Ogre => MobConstants.OgreEyeWhitesColor,
            MobRaces.Demon => MobConstants.DemonEyeWhitesColor,
            _ => Colors.White
        };
        MobUtils.SetMeshColor(eyeWhiteColor, eyesMesh, 0);
        
        // lashes color
        var lashesMesh = skeleton.GetNode<MeshInstance3D>("Eyelashes");
        var lashesColor = race == MobRaces.Statue ? MobConstants.ColorStatueGrey : Colors.Black;
        MobUtils.SetMeshColor(lashesColor, lashesMesh, 0);
    }
    
    public static BodyData AdjustBodyData(List<NormInfo> norms, BodyData bodyData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var current = MobUtils.GetBodyDataFieldValue(bodyData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, meshInfo, norms, current);
            MobUtils.SetDataToBodyDataField(bodyData, meshInfo.FieldName, adjusted);
        }
        MobUtils.PropagateHairColor(bodyData);
        return bodyData;
    }
    public static EquipmentData AdjustEquipmentData(List<NormInfo> norms, EquipmentData eqData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var current = MobUtils.GetEqDataFieldValue(eqData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, meshInfo, norms, current);
            MobUtils.SetDataToEqDataField(eqData, meshInfo.FieldName, adjusted);
        }
        return eqData;
    }
    private static MeshData AdjustMeshData(string meshName, MobMeshInfo meshInfo, List<NormInfo> norms, MeshData meshData)
    {
        meshData.MeshFile = MobGetter.GetRandomMeshFile(meshName, norms, meshInfo.FileFolder, meshData.MeshFile);
        meshData.MeshColor = MobGetter.GetRandomMeshColor(norms, meshInfo.Colors, meshData.MeshColor);
        meshData.MeshShapes = MobGetter.GetRandomMeshShapes(norms, meshInfo.Shapes, meshData.MeshShapes);
        return meshData;
    }

}

