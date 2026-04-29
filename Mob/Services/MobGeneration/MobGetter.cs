using System;
using System.Collections.Generic;
using System.Linq;
using CharacterDemo.General;
using CharacterDemo.General.Services;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.InfoFiles;
using Godot;
using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.Services.MobGeneration;

public static class MobGetter
{
    private static readonly Random Rng = new();

    //  GET 

    public static MobData GetRandomMobData(Skeleton3D skeleton, MobRaces race = (MobRaces)(-1),
        MobTypes type = (MobTypes)(-1), Gender gender = (Gender)(-1),
        string mobName = "empty", MobData? mobData = null)
    {
        mobData ??= new MobData { Race = race, Type = type, Gender = gender };

        if ((int)mobData.Race < 0) mobData.Race = (MobRaces)Rng.Next(Enum.GetValues<MobRaces>().Length);
        if ((int)mobData.Type < 0) mobData.Type = (MobTypes)Rng.Next(Enum.GetValues<MobTypes>().Length);
        if ((int)mobData.Gender < 0) mobData.Gender = Rng.NextDouble() > MobConstants.VariationChance
            ? (Rng.Next(2) == 0 ? Gender.Male : Gender.Female)
            : Gender.NonBin;

        var norms = GetRtgNorms(mobData.Race, mobData.Type, mobData.Gender);
        mobData.BodyData = GetRandomBodyData(skeleton, norms, mobData.BodyData);
        mobData.EquipmentData = GetRandomEquipmentData(skeleton, norms, mobData.EquipmentData);
        var names = MobConstants.MobNames[mobData.Gender];
        mobData.MobName = mobName != "empty" ? mobName : names[Rng.Next(names.Length)];
        return mobData;
    }

    public static List<NormInfo> GetRtgNorms(MobRaces race, MobTypes type, Gender gender)
    {
        var norms = new List<NormInfo>();
        norms.AddRange(MobConstants.RaceNorms[race]);
        norms.AddRange(MobConstants.TypeNorms[type]);
        norms.AddRange(MobConstants.GenderNorms[gender]);
        return norms;
    }

    //  RANDOM (fresh) 

    public static BodyData GetRandomBodyData(Skeleton3D skeleton, List<NormInfo> norms, BodyData? bodyData = null)
    {
        bodyData ??= new BodyData();
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
            var shapeNames = GetShapeNames(meshName, meshInstance);
            SetBodyMeshData(bodyData, meshName, meshInfo.FieldName, GetRandomMeshData(meshName, shapeNames, meshInfo, norms));
        }
        MobUtils.PropagateHairColor(bodyData);
        return bodyData;
    }

    public static EquipmentData GetRandomEquipmentData(Skeleton3D skeleton, List<NormInfo> norms, EquipmentData? eqData = null)
    {
        eqData ??= new EquipmentData();
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
            var shapeNames = GetShapeNames(meshName, meshInstance);
            SetEqMeshData(eqData, meshName, meshInfo.FieldName, GetRandomMeshData(meshName, shapeNames, meshInfo, norms));
        }
        return eqData;
    }

    public static MeshData GetRandomMeshData(string meshName, IReadOnlyList<string> shapeNames, MobMeshInfo meshInfo, List<NormInfo> norms)
    {
        var md = new MeshData
        {
            MeshFile = GetRandomMeshFile(meshName, norms, meshInfo.FileFolder),
            MeshColor = GetRandomMeshColor(meshName, norms, meshInfo.Colors),
            MeshShape = GetRandomMeshShape(meshName, norms, meshInfo.Shapes, shapeNames).ToList()
        };
        return md;
    }

    public static string GetRandomMeshFile(string meshName, List<NormInfo> norms, string fileFolder)
    {
        if (string.IsNullOrEmpty(fileFolder)) return "";
        var allTags = FileService.LoadJson<Dictionary<string, List<string>>>(fileFolder + "tag_info.json") ?? new();
        var tagNorms = norms.Where(n => n.Tags.Any()).ToList();
        var meshNorms = norms.Where(n => n.Meshes.Any()).ToList();
        var allFiles = GetAllFileNames(meshName, fileFolder);
        if (allFiles.Count == 0) { GD.Print("No files for ", meshName); return "empty"; }

        if (Rng.NextDouble() <= MobConstants.VariationChance)
        {
            tagNorms = tagNorms.Where(n => n.Enforce).ToList();
            meshNorms = meshNorms.Where(n => n.Enforce).ToList();
        }
        return PickValidMeshFile(allFiles, allTags, meshName, tagNorms, meshNorms);
    }

    public static Color GetRandomMeshColor(string meshName, List<NormInfo> norms, IReadOnlyList<Color> allColors)
    {
        if (allColors.Count == 0) return Colors.Black;
        var colorNorms = norms.Where(n => n.Colors.Any()).ToList();
        if (Rng.NextDouble() <= MobConstants.VariationChance)
            colorNorms = colorNorms.Where(n => n.Enforce).ToList();
        return PickValidMeshColor(allColors, meshName, colorNorms);
    }

    public static float[] GetRandomMeshShape(string meshName, List<NormInfo> norms,
        IReadOnlyList<MobShapeInfo> shapes, IReadOnlyList<string> shapeNames)
    {
        if (shapes.Count == 0 || shapeNames.Count != shapes.Count) return [];
        var shapeNorms = norms.Where(n => n.Shapes.Any()).ToList();
        var result = new List<float>();
        for (int i = 0; i < shapeNames.Count; i++)
        {
            var shapeInfo = shapes.FirstOrDefault(s => s.ShapeName == shapeNames[i]);
            if (shapeInfo == null || shapeInfo.Values.Count == 0) { result.Add(0f); continue; }
            var active = Rng.NextDouble() <= MobConstants.VariationChance ? shapeNorms.Where(n => n.Enforce).ToList() : shapeNorms;
            result.Add(PickValidMeshShape(shapeInfo.Values, i, meshName, active));
        }
        return [.. result];
    }

    //  INTERNAL HELPERS 

    public static IReadOnlyList<string> GetShapeNames(string meshName, MeshInstance3D? meshInstance)
    {
        if (!MobConstants.MeshesWithShapes.Contains(meshName) || meshInstance == null) return [];
        return MobUtils.GetShapeNamesFromMesh(meshInstance.Mesh);
    }

    public static List<string> GetAllFileNames(string meshName, string fileFolder)
    {
        if (MobConstants.HalfEmptyNames.Contains(meshName) && Rng.NextDouble() > 0.5)
            return ["empty"];
        var files = new List<string>(FileService.GetFileNames(fileFolder));
        if (!MobConstants.NonEmptyNames.Contains(meshName) && !string.IsNullOrEmpty(fileFolder))
            files.Insert(0, "empty");
        return files;
    }

    public static string PickValidMeshFile(List<string> allFiles, Dictionary<string, List<string>> allTags,
        string meshName, List<NormInfo> tagNorms, List<NormInfo> meshNorms)
    {
        var possible = new List<string>(allFiles);

        foreach (var norm in tagNorms)
        {
            var tags = norm.Tags;
            var filtered = possible.Where(f =>
            {
                var fileTags = allTags.TryGetValue(f, out var t) ? t : new List<string>();
                return norm.Forbidden
                    ? !GeneralUtils.HasAny(fileTags, tags)
                    : fileTags.Count > 0 && GeneralUtils.HasAll(fileTags, tags);
            }).ToList();
            if (filtered.Count > 0) possible = filtered;
        }

        foreach (var norm in meshNorms)
        {
            if (!norm.Meshes.TryGetValue(meshName, out var target)) continue;
            if (!norm.Forbidden && !possible.Contains(target)) possible.Add(target);
            var filtered = possible.Where(f => norm.Forbidden ? f != target : f == target).ToList();
            if (filtered.Count > 0) possible = filtered;
        }

        return possible.Count > 0 ? possible[Rng.Next(possible.Count)] : "empty";
    }

    public static Color PickValidMeshColor(IReadOnlyList<Color> allColors, string meshName, List<NormInfo> colorNorms)
    {
        var possible = new List<Color>(allColors);
        foreach (var norm in colorNorms)
        {
            if (!norm.Colors.TryGetValue(meshName, out var normColors)) continue;
            if (norm.Forbidden)
            {
                var filtered = possible.Where(c => !normColors.Contains(c)).ToList();
                if (filtered.Count > 0) possible = filtered;
            }
            else if (normColors.Count > 0)
            {
                possible = new List<Color>(normColors);
            }
        }
        return possible.Count > 0 ? possible[Rng.Next(possible.Count)] : Colors.Black;
    }

    public static float PickValidMeshShape(IReadOnlyList<float> allValues, int shapeId, string meshName, List<NormInfo> shapeNorms)
    {
        var possible = new List<float>(allValues);
        foreach (var norm in shapeNorms)
        {
            if (!norm.Shapes.TryGetValue(meshName, out var shapeDict) || !shapeDict.TryGetValue(shapeId, out var vals)) continue;
            var filtered = possible.Where(v => norm.Forbidden ? !vals.Contains(v) : vals.Contains(v)).ToList();
            if (filtered.Count > 0) possible = filtered;
        }
        return possible.Count > 0 ? possible[Rng.Next(possible.Count)] : 0f;
    }

    // Helpers to set mesh data on data objects by field name
    public static void SetBodyMeshData(BodyData bodyData, string meshName, string fieldName, MeshData meshData)
    {
        switch (fieldName)
        {
            case "body_mesh": bodyData.BodyMesh = meshData; break;
            case "head_mesh": bodyData.HeadMesh = meshData; break;
            case "eye_mesh": bodyData.EyeMesh = meshData; break;
            case "lashes_mesh": bodyData.LashesMesh = meshData; break;
            case "hair_mesh": bodyData.HairMesh = meshData; break;
            case "beard_mesh": bodyData.BeardMesh = meshData; break;
            case "brow_mesh": bodyData.BrowMesh = meshData; break;
        }
    }

    public static void SetEqMeshData(EquipmentData eqData, string meshName, string fieldName, MeshData meshData)
    {
        switch (fieldName)
        {
            case "top_mesh": eqData.TopMesh = meshData; break;
            case "bottom_mesh": eqData.BottomMesh = meshData; break;
            case "shoe_mesh": eqData.ShoeMesh = meshData; break;
            case "hat_mesh": eqData.HatMesh = meshData; break;
            case "r_hand_mesh": eqData.RHandMesh = meshData; break;
            case "l_hand_mesh": eqData.LHandMesh = meshData; break;
            case "accessory_mesh": eqData.AccessoryMesh = meshData; break;
        }
    }

    public static MeshData GetBodyMeshData(BodyData bodyData, string fieldName) => fieldName switch
    {
        "body_mesh" => bodyData.BodyMesh,
        "head_mesh" => bodyData.HeadMesh,
        "eye_mesh" => bodyData.EyeMesh,
        "lashes_mesh" => bodyData.LashesMesh,
        "hair_mesh" => bodyData.HairMesh,
        "beard_mesh" => bodyData.BeardMesh,
        "brow_mesh" => bodyData.BrowMesh,
        _ => new MeshData()
    };

    public static MeshData GetEqMeshData(EquipmentData eqData, string fieldName) => fieldName switch
    {
        "top_mesh" => eqData.TopMesh,
        "bottom_mesh" => eqData.BottomMesh,
        "shoe_mesh" => eqData.ShoeMesh,
        "hat_mesh" => eqData.HatMesh,
        "r_hand_mesh" => eqData.RHandMesh,
        "l_hand_mesh" => eqData.LHandMesh,
        "accessory_mesh" => eqData.AccessoryMesh,
        _ => new MeshData()
    };
}
