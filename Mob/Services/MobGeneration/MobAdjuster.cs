using System.Collections.Generic;
using System.Linq;
using CharacterDemo.General;
using CharacterDemo.General.Services;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.InfoFiles;
using Godot;
using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.Services.MobGeneration;

public static class MobAdjuster
{
    private static readonly System.Random Rng = new();
    //  ADJUST (keep valid, re-randomize invalid) 
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
    public static BodyData AdjustBodyData(Skeleton3D skeleton, List<NormInfo> norms, BodyData bodyData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
            var shapeNames = MobGetter.GetShapeNames(meshName, meshInstance);
            var current = MobGetter.GetBodyMeshData(bodyData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, shapeNames, meshInfo, norms, current);
            MobGetter.SetBodyMeshData(bodyData, meshName, meshInfo.FieldName, adjusted);
        }
        MobUtils.PropagateHairColor(bodyData);
        return bodyData;
    }
    public static EquipmentData AdjustEquipmentData(Skeleton3D skeleton, List<NormInfo> norms, EquipmentData eqData)
    {
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
            var shapeNames = MobGetter.GetShapeNames(meshName, meshInstance);
            var current = MobGetter.GetEqMeshData(eqData, meshInfo.FieldName);
            var adjusted = AdjustMeshData(meshName, shapeNames, meshInfo, norms, current);
            MobGetter.SetEqMeshData(eqData, meshName, meshInfo.FieldName, adjusted);
        }
        return eqData;
    }

    private static MeshData AdjustMeshData(string meshName, IReadOnlyList<string> shapeNames, MobMeshInfo meshInfo,
        List<NormInfo> norms, MeshData meshData)
    {
        meshData.MeshFile = AdjustMeshFile(meshName, meshData.MeshFile, norms, meshInfo.FileFolder);
        meshData.MeshColor = AdjustMeshColor(meshName, meshData.MeshColor, norms, meshInfo.Colors);
        meshData.MeshShape = AdjustMeshShape(meshName, meshData.MeshShape, norms, meshInfo.Shapes, shapeNames);
        return meshData;
    }

    //  ADJUST helpers 
    private static string AdjustMeshFile(string meshName, string meshFile, List<NormInfo> norms, string fileFolder)
    {
        if (string.IsNullOrEmpty(fileFolder)) return "";
        var allTags = FileService.LoadJson<Dictionary<string, List<string>>>(fileFolder + "tag_info.json") ?? new();
        var selectedTags = allTags.TryGetValue(meshFile, out var t) ? t : new List<string>();
        var tagNorms = norms.Where(n => n.Tags.Any()).ToList();
        var meshNorms = norms.Where(n => n.Meshes.Any()).ToList();
        if (IsMeshFileWithinNorms(meshFile, meshName, selectedTags, tagNorms, meshNorms)) return meshFile;
        var allFiles = MobGetter.GetAllFileNames(meshName, fileFolder);
        if (Rng.NextDouble() <= MobConstants.VariationChance)
        {
            tagNorms = tagNorms.Where(n => n.Enforce).ToList();
            meshNorms = meshNorms.Where(n => n.Enforce).ToList();
        }
        return MobGetter.PickValidMeshFile(allFiles, allTags, meshName, tagNorms, meshNorms);
    }

    private static Color AdjustMeshColor(string meshName, Color meshColor, List<NormInfo> norms, IReadOnlyList<Color> allColors)
    {
        if (allColors.Count == 0) return Colors.Black;
        var colorNorms = norms.Where(n => n.Colors.Any()).ToList();

        if (IsMeshColorWithinNorms(meshColor, meshName, colorNorms))
            return meshColor;

        var effectivePool = new List<Color>(allColors);
        foreach (var norm in colorNorms)
        {
            if (!norm.Colors.TryGetValue(meshName, out var normColors)) continue;
            if (norm.Forbidden)
            {
                var filtered = effectivePool.Where(c => !normColors.Contains(c)).ToList();
                if (filtered.Count > 0) effectivePool = filtered;
            }
            else if (normColors.Count > 0)
                effectivePool = new List<Color>(normColors);
        }

        if (effectivePool.Contains(meshColor)) return meshColor;
        if (Rng.NextDouble() <= MobConstants.VariationChance)
            colorNorms = colorNorms.Where(n => n.Enforce).ToList();
        return MobGetter.PickValidMeshColor(allColors, meshName, colorNorms);
    }

    private static List<float> AdjustMeshShape(string meshName, List<float> meshShape, List<NormInfo> norms,
        IReadOnlyList<MobShapeInfo> shapes, IReadOnlyList<string> shapeNames)
    {
        if (shapes.Count == 0 || shapeNames.Count != shapes.Count) return meshShape;
        var shapeNorms = norms.Where(n => n.Shapes.Any()).ToList();
        var result = new List<float>();
        for (int i = 0; i < shapeNames.Count; i++)
        {
            float? current = (meshShape.Count > i) ? meshShape[i] : null;
            if (current != null && IsMeshShapeWithinNorms(current.Value, meshName, i, shapeNorms))
                result.Add(current.Value);
            else
            {
                var shapeInfo = shapes.FirstOrDefault(s => s.ShapeName == shapeNames[i]);
                if (shapeInfo == null || shapeInfo.Values.Count == 0) { result.Add(0f); continue; }
                var active = Rng.NextDouble() <= MobConstants.VariationChance ? shapeNorms.Where(n => n.Enforce).ToList() : shapeNorms;
                result.Add(MobGetter.PickValidMeshShape(shapeInfo.Values, i, meshName, active));
            }
        }
        return [.. result];
    }

    //  VALIDATION 
    private static bool IsMeshFileWithinNorms(string meshFile, string meshName, List<string> tags,
        List<NormInfo> tagNorms, List<NormInfo> meshNorms)
    {
        if (string.IsNullOrEmpty(meshFile)) return false;
        foreach (var norm in tagNorms)
        {
            if (!norm.Forbidden && !GeneralUtils.HasAll(tags, norm.Tags)) return false;
            if (norm.Forbidden && GeneralUtils.HasAny(tags, norm.Tags)) return false;
        }
        foreach (var norm in meshNorms)
        {
            if (!norm.Meshes.TryGetValue(meshName, out var target)) continue;
            bool hasValue = target == meshFile;
            if (!norm.Forbidden && !hasValue) return false;
            if (norm.Forbidden && hasValue) return false;
        }
        return true;
    }

    private static bool IsMeshColorWithinNorms(Color color, string meshName, List<NormInfo> colorNorms)
    {
        if (color == new Color()) return false;
        foreach (var norm in colorNorms)
        {
            if (!norm.Colors.TryGetValue(meshName, out var normColors)) continue;
            bool hasValue = normColors.Contains(color);
            if (!norm.Forbidden && !hasValue) return false;
            if (norm.Forbidden && hasValue) return false;
        }
        return true;
    }

    private static bool IsMeshShapeWithinNorms(float shapeValue, string meshName, int shapeId, List<NormInfo> shapeNorms)
    {
        foreach (var norm in shapeNorms)
        {
            if (!norm.Shapes.TryGetValue(meshName, out var shapeDict) || !shapeDict.TryGetValue(shapeId, out var vals)) continue;
            bool hasValue = vals.Contains(shapeValue);
            if (!norm.Forbidden && !hasValue) return false;
            if (norm.Forbidden && hasValue) return false;
        }
        return true;
    }
}

