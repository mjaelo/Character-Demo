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
    public static void AdjustMobToRace(Scenes.Mob.Mob mob, MobRaces race)
    {
        var dict = MobConstants.ExtraRaceActions[race];
        var skeleton = mob.GetNode<Skeleton3D>("body/Armature/Skeleton3D");

        bool showMonsterBody = dict.ContainsKey("show_monster_body") && dict["show_monster_body"].AsBool();
        skeleton.GetNode<Node3D>("monster-body").Visible = showMonsterBody;

        var bodyMeshNames = new List<string>(["Eyelashes", "Brows", "Eyes"]);
        bodyMeshNames.AddRange(MobConstants.MeshesWithSkin);
        foreach (var child in skeleton.GetChildren().OfType<MeshInstance3D>())
            if (bodyMeshNames.Contains(child.Name))
                child.Visible = !showMonsterBody;

        mob.Scale = dict.ContainsKey("scale") ? Vector3.One * dict["scale"].AsSingle() : Vector3.One;

        var bodyMesh = skeleton.GetNode<MeshInstance3D>("Top");
        var material = (StandardMaterial3D?)bodyMesh.GetActiveMaterial(0);
        if (material != null)
            material.AlbedoTextureMsdf = race is MobRaces.Statue or MobRaces.Spirit;

        var eyeWhites = dict.ContainsKey("eye_whites") ? dict["eye_whites"].As<Color>() : Colors.White;
        var eyePupil = dict.ContainsKey("eye_pupil") ? dict["eye_pupil"].As<Color>() : Colors.Black;

        var eyesMesh = skeleton.GetNode<MeshInstance3D>("Eyes");
        var lashesMesh = skeleton.GetNode<MeshInstance3D>("Eyelashes");
        var statueColor = race == MobRaces.Statue ? MobConstants.ColorStatueGrey : eyeWhites;
        MobUtils.SetMeshColor(statueColor, eyesMesh, 0);
        MobUtils.SetMeshColor(race == MobRaces.Statue ? MobConstants.ColorStatueGrey : eyePupil, eyesMesh, 2);
        MobUtils.SetMeshColor(race == MobRaces.Statue ? MobConstants.ColorStatueGrey : Colors.Black, lashesMesh, 0);
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

