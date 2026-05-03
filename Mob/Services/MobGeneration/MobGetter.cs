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

    //  GET 
    public static MobData GetRandomMobData(MobRaces race = (MobRaces)(-1), MobTypes type = (MobTypes)(-1), Gender gender = (Gender)(-1), string mobName = "empty", MobData? mobData = null)
    {
        mobData ??= new MobData { Race = race, Type = type, Gender = gender };

        if ((int)mobData.Race < 0) mobData.Race = GeneralUtils.PickRandom(Enum.GetValues<MobRaces>());
        if ((int)mobData.Type < 0) mobData.Type = GeneralUtils.PickRandom(Enum.GetValues<MobTypes>());
        if ((int)mobData.Gender < 0) mobData.Gender = GeneralUtils.CheckRng(MobConstants.VariationChance) 
            ? Gender.NonBin
            : (GeneralUtils.CheckRng(0.5f) ? Gender.Male : Gender.Female);

        var norms = GetRtgNorms(mobData.Race, mobData.Type, mobData.Gender);
        mobData.BodyData = GetRandomBodyData(norms, mobData.BodyData);
        mobData.EquipmentData = GetRandomEquipmentData(norms, mobData.EquipmentData);
        var possibleNames = MobConstants.MobNames[mobData.Gender];
        mobData.MobName = mobName != "empty" ? mobName : GeneralUtils.PickRandom(possibleNames);
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

    public static BodyData GetRandomBodyData(List<NormInfo> norms, BodyData? bodyData = null)
    {
        bodyData ??= new BodyData();
        foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
        {
            var meshNorms = norms.Where(norm => !norm.MeshNames.Any() || norm.MeshNames.Contains(meshName) || norm.MeshNames.Contains("BodyBulk")).ToList();
            MobUtils.SetDataToBodyDataField(bodyData, meshInfo.FieldName, GetRandomMeshData(meshName, meshInfo, meshNorms));
        }
        MobUtils.PropagateHairColor(bodyData);
        return bodyData;
    }

    public static EquipmentData GetRandomEquipmentData(List<NormInfo> norms, EquipmentData? eqData = null)
    {
        eqData ??= new EquipmentData();
        foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
        {
            var meshNorms = norms.Where(norm => !norm.MeshNames.Any() || norm.MeshNames.Contains(meshName) || norm.MeshNames.Contains("EquipmentBulk")).ToList();
            MobUtils.SetDataToEqDataField(eqData, meshInfo.FieldName, GetRandomMeshData(meshName, meshInfo, meshNorms));
        }
        return eqData;
    }

    private static MeshData GetRandomMeshData(string meshName, MobMeshInfo meshInfo, List<NormInfo> meshNorms)
    {
        var md = new MeshData
        {
            MeshFile = GetRandomMeshFile(meshName, meshNorms, meshInfo.FileFolder),
            MeshColor = GetRandomMeshColor(meshNorms, meshInfo.Colors),
            MeshShapes = GetRandomMeshShapes(meshNorms, meshInfo.Shapes)
        };
        return md;
    }

    public static string GetRandomMeshFile(string meshName, List<NormInfo> meshNorms, string fileFolder, string defaultValue = "")
    {
        if (string.IsNullOrEmpty(fileFolder)) return "";
        bool ignoreNorms = GeneralUtils.CheckRng(MobConstants.VariationChance);
        var tagNorms = meshNorms.Where(n => n.Tags.Any() && !(ignoreNorms && !n.Enforce)).ToList();
        var fileNorms = meshNorms.Where(n => n.Files.Any() && !(ignoreNorms && !n.Enforce)).ToList();
        
        var fileTags = FileService.LoadJson<Dictionary<string, List<string>>>(fileFolder + "tag_info.json") ?? new();
        var allFiles = GetAllFileNames(meshName, fileFolder);
        
        // adding empty option if required but missing (for skeleton: lashes, top, shoes) TODO why not bottom? somethings wrong here... handle it in GetAllFileNames?
        if (!allFiles.Contains("empty") && fileNorms.Any(n => n.Enforce && !n.Forbidden && n.Files.Contains("empty")))
            allFiles.Insert(0, "empty");
        
        if (allFiles.Count == 0) { GD.Print("No files for ", fileFolder); return "empty"; }
        var possibleFiles= FilterValidMeshFile(allFiles, fileTags, tagNorms, fileNorms);
        return possibleFiles.Contains(defaultValue) ? defaultValue : GeneralUtils.PickRandom(possibleFiles);
    }

    public static Color GetRandomMeshColor(List<NormInfo> meshNorms, IReadOnlyList<Color> allColors,Color defaultValue = new())
    {
        if (allColors.Count == 0) return Colors.Black;
        bool ignoreNorms = GeneralUtils.CheckRng(MobConstants.VariationChance);
        var colorNorms = meshNorms.Where(n => n.Colors.Any() && !(ignoreNorms && !n.Enforce)).ToList();
        var possibleColors= FilterValidMeshColor(allColors, colorNorms);
        return possibleColors.Contains(defaultValue) ? defaultValue : GeneralUtils.PickRandom(possibleColors);
    }

    public static IReadOnlyList<float>  GetRandomMeshShapes(List<NormInfo> meshNorms, IReadOnlyList<MobShapeInfo> shapes,IReadOnlyList<float>?defaultValues = null)
    {
        if (shapes.Count == 0) return [];
        var shapeNorms = meshNorms.Where(n => n.Shapes.Any()).ToList();
        var result = new List<float>();
        for (int i = 0; i < shapes.Count; i++)
        {
            var shapeInfo = shapes[i];
            var defaultValue = defaultValues?.Count > i ? defaultValues[i] : float.NegativeInfinity;
            bool ignoreNorms = GeneralUtils.CheckRng(MobConstants.VariationChance);
            var activeNorms = ignoreNorms ? shapeNorms.Where(n => n.Enforce).ToList() : shapeNorms;
            var possibleValues = FilterValidMeshShape(shapeInfo.Values, i, activeNorms);
            var pickedValue = possibleValues.Count > 0 && !possibleValues.Contains(defaultValue) ? GeneralUtils.PickRandom(possibleValues) : defaultValue;
            result.Add(pickedValue);
        }
        return result;
    }

    //  INTERNAL HELPERS 
    private static List<string> GetAllFileNames(string meshName, string fileFolder)
    {
        if (MobConstants.HalfEmptyNames.Contains(meshName) && GeneralUtils.CheckRng(0.5f))
            return ["empty"];
        var files = new List<string>(FileService.GetFileNames(fileFolder));
        if (!MobConstants.NonEmptyNames.Contains(meshName) || string.IsNullOrEmpty(fileFolder))
            files.Insert(0, "empty");
        return files;
    }

    private static List<string> FilterValidMeshFile(List<string> allFiles, Dictionary<string, List<string>> allTags, List<NormInfo> tagNorms, List<NormInfo> fileNorms)
    {
        var possibleFiles = new List<string>(allFiles);

        foreach (var norm in tagNorms)
        {
            var tags = norm.Tags;
            var filteredFiles = possibleFiles.Where(fileName =>
            {
                var fileTags = allTags.TryGetValue(fileName, out var t) ? t : new List<string>();
                return norm.Forbidden
                    ? !GeneralUtils.HasAny(fileTags, tags)
                    : fileTags.Count > 0 && GeneralUtils.HasAll(fileTags, tags);
            }).ToList();
            if (filteredFiles.Count > 0) possibleFiles = filteredFiles;
        }

        foreach (var norm in fileNorms)
        {
            var filteredFiles = possibleFiles.Where(fileName => norm.Forbidden ? !norm.Files.Contains(fileName) : norm.Files.Contains(fileName)).ToList();
            if (filteredFiles.Count > 0) possibleFiles = filteredFiles;
        }

        return possibleFiles;
    }

    private static List<Color> FilterValidMeshColor(IReadOnlyList<Color> allColors, List<NormInfo> colorNorms)
    {
        var possibleColors = new List<Color>(allColors);
        foreach (var norm in colorNorms)
        {
            List<Color> filteredColors = norm.Forbidden ? possibleColors.Where(color => !norm.Colors.Contains(color)).ToList() : norm.Colors.ToList();
            if (filteredColors.Count > 0) possibleColors = filteredColors;
        }
        return possibleColors;
    }

    private static List<float> FilterValidMeshShape(IReadOnlyList<float> allValues, int shapeId, List<NormInfo> shapeNorms)
    {
        var possibleValues = new List<float>(allValues);
        foreach (var norm in shapeNorms)
        {
            var filteredValues = possibleValues.Where(val =>
            {
                var shapes = norm.Shapes.TryGetValue(shapeId, out var s) ? s : [];
                return norm.Forbidden ? !shapes.Contains(val) : shapes.Contains(val);
            }).ToList();
            if (filteredValues.Count > 0) possibleValues = filteredValues;
        }
        return possibleValues;
    }
}
