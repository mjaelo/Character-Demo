using System;
using System.Collections.Generic;
using System.Collections.Immutable;
using System.Linq;
using CharacterDemo.General.Services;
using CharacterDemo.Mob.InfoFiles;
using Godot;
using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob;

// TODO
//  add more variation probabilities: nonbin prob, hat prob
//  add tag validation from tag_list variable?
public static class MobConstants 
{
    //  Generation constants 
    public const float VariationChance = 0.1f;
    public const float RaceCamHeightDefault = 6.7f;
    public static readonly IReadOnlyDictionary<MobRaces, float> RaceCamHeights = new Dictionary<MobRaces, float> { [MobRaces.Ogre] = 10f, [MobRaces.Spirit] = 5f };
    public static readonly IReadOnlyDictionary<Gender, string[]> MobNames = LoadMobNames(MobNamesPath);
    // Main material indices for specific mesh names (by resource path substring)
    public static readonly Dictionary<string, int> MainMaterials = new()
    {
        ["merchant-top"] = 2,
        ["merchant-hat"] = 2,
        ["guard-bottom"] = 1,
        ["guard-top"] = 2
    };
    public static string[] FullHats = ["guard-hat"];
    
    //  Paths 
    public const string MobScenePath = "res://Mob/Scenes/Mob/Mob.tscn";
    private const string GenderNormsPath = "res://Assets/Mob/Constants/GenderNorms.json";
    private const string TypeNormsPath = "res://Assets/Mob/Constants/TypeNorms.json";
    private const string RaceNormsPath = "res://Assets/Mob/Constants/RaceNorms.json";
    private const string MobNamesPath = "res://Assets/Mob/Constants/MobNames.json";

    //  Mob mesh name groups 
    public static readonly string[] MeshesWithSkin = ["Top", "Bottom", "Head"];
    public static readonly string[] HandNames = ["Right Hand", "Left Hand"];
    public static readonly string[] WeaponNames = ["Sword", "Shield"];
    public static readonly string[] NonEmptyNames = ["Top", "Bottom", "Shoes", "Eyelashes"];
    public static readonly string[] HairLinkedNames = ["Brows", "Beard"];
    public static readonly string[] HairAdjustingNames = ["Hair", "Hat"];
    public static readonly string[] HalfEmptyNames = ["Hat", "Beard"];
    public static readonly string[] GenderedMeshNames = ["Beard", "Eyelashes"];
    public static readonly string[] HipMovers = ["Body Shape", "Body Mass"];
    public static readonly string[] MeshesWithShapes = ["Body", "Brows", "Head"];
    public static readonly string[] ClothMeshNames = ["Top", "Bottom", "Shoes", "Hat", "Left Hand", "Right Hand"];

    //  Colors 
    public static readonly Color ColorStatueGrey = new(0.3f, 0.3f, 0.3f, 0f);
    private static readonly IReadOnlyList<Color>  HairColors = GetColorsFromColorRange(new Vector2(0, .2f), new Vector2(.1f, .4f), new Vector2(0, .7f));
    private static readonly IReadOnlyList<Color>  ClothesColors = GetColorsFromColorRange(new Vector2(0f, .27f), new Vector2(0f, .3f), new Vector2(.2f, .6f));
    private static readonly IReadOnlyList<Color>  EyeColors = GetColorsFromColorRange(new Vector2(.1f, .6f), new Vector2(.2f, .5f), new Vector2(.3f, .8f));
    private static readonly IReadOnlyList<Color> SkinColors = GetColorsFromColorRange(new Vector2(.01f, .08f), new Vector2(.2f, .3f), new Vector2(.3f, .95f));
    public static readonly IReadOnlyList<Color> DemonSkinColors  = [Colors.DarkRed];
    public static readonly IReadOnlyList<Color> DemonClothesColors  = [Colors.Black];
    public static readonly IReadOnlyList<Color> StatueColors  = [ColorStatueGrey];
    public static readonly IReadOnlyList<Color> OgreColors  = [Colors.DarkOliveGreen];
    public static readonly IReadOnlyList<Color> SpiritEyesColors  = [new(10, 10, 10, 5f)];
    public static readonly IReadOnlyList<Color> SpiritSkinColors  = GetColorsFromColorRange(new Vector2(.1f, .6f), new Vector2(.2f, .5f), new Vector2(.3f, .8f), new Vector2(5, 5));

    //  Extra Actions to perform per race switch  TODO can be better stored in custom objects or in json
    public static readonly IReadOnlyDictionary<MobRaces, IReadOnlyDictionary<string, Variant>> ExtraRaceActions =
        new Dictionary<MobRaces, IReadOnlyDictionary<string, Variant>>
        {
            [MobRaces.Human] = ImmutableDictionary<string, Variant>.Empty,
            [MobRaces.Skeleton] = new Dictionary<string, Variant> { ["show_monster_body"] = true },
            [MobRaces.Spirit] = new Dictionary<string, Variant> { ["scale"] = 0.75f, ["eye_whites"] = new Color(100, 100, 100), ["eye_pupil"] = new Color(100, 100, 100) },
            [MobRaces.Ogre] = new Dictionary<string, Variant> { ["scale"] = 1.5f, ["eye_whites"] = Colors.Orange },
            [MobRaces.Demon] = new Dictionary<string, Variant> { ["eye_whites"] = Colors.Black },
            [MobRaces.Statue] = ImmutableDictionary<string, Variant>.Empty,
        };

  
    //  Norms 
    public static readonly IReadOnlyDictionary<Gender, IReadOnlyList<NormInfo>> GenderNorms = LoadNorms<Gender>(GenderNormsPath);
    public static readonly IReadOnlyDictionary<MobTypes, IReadOnlyList<NormInfo>> TypeNorms = LoadNorms<MobTypes>(TypeNormsPath);
    public static readonly IReadOnlyDictionary<MobRaces, IReadOnlyList<NormInfo>> RaceNorms = LoadNorms<MobRaces>(RaceNormsPath);
    
    //  Mesh info dictionaries 
    private static readonly IReadOnlyList<MobShapeInfo> BodyShapes = [new("Body Shape", GetFloatRange(0)), new("Body Mass", GetFloatRange(-0.5f)), new("Body Muscles",GetFloatRange(-0.5f))];
    private static readonly IReadOnlyList<MobShapeInfo> HeadShapes = [new("Lips Width"), new("Lips Thickness"), new("Lip Corner"), new("Jaw Shape"), new("Face Length"), new("Eye Lower Lid Height"),  new("Eye Upper Lid Height"), new("Eye Edge Height") ];
    private static readonly IReadOnlyList<MobShapeInfo> BrowShapes = [new("Brow Thickness",GetFloatRange(0)), new("Brow Inner Height",GetFloatRange(0)), new("Brow Outer Height",GetFloatRange(0)) ];
    private static readonly IReadOnlyList<MobShapeInfo> LashShapes = [new("Eye Lower Lid Height"), new("Eye Upper Lid Height"), new("Eye Edge Height")];
    private static readonly IReadOnlyList<MobShapeInfo> BeardShapes = [new("Jaw Shape"), new("Face Length")];
    
    public static  readonly IReadOnlyDictionary<string, MobMeshInfo> BodyMeshesInfo = new Dictionary<string, MobMeshInfo>
        {
            ["Body"] = new("body_mesh", "", SkinColors, BodyShapes),
            ["Head"] = new("head_mesh", "", null, HeadShapes),
            ["Eyes"] = new("eye_mesh", "", EyeColors),
            ["Eyelashes"] = new("lashes_mesh", "res://Assets/Mob/Meshes/face/lashes/",null, LashShapes),
            ["Hair"] = new("hair_mesh", "res://Assets/Mob/Meshes/hair/", HairColors),
            ["Beard"] = new("beard_mesh", "res://Assets/Mob/Meshes/face/beard/", null, BeardShapes),
            ["Brows"] = new("brow_mesh", "", null, BrowShapes) 
        };

    public static readonly IReadOnlyDictionary<string, MobMeshInfo> EqMeshesInfo = new Dictionary<string, MobMeshInfo>
        {
            ["Top"] = new("top_mesh", "res://Assets/Mob/Meshes/top/", ClothesColors, BodyShapes),
            ["Bottom"] = new("bottom_mesh", "res://Assets/Mob/Meshes/bottom/", ClothesColors, BodyShapes),
            ["Shoes"] = new("shoe_mesh", "res://Assets/Mob/Meshes/shoes/", ClothesColors),
            ["Hat"] = new("hat_mesh", "res://Assets/Mob/Meshes/hat/", ClothesColors),
            ["Right Hand"] = new("r_hand_mesh", "res://Assets/Mob/Meshes/r_hand/"),
            ["Left Hand"] = new("l_hand_mesh", "res://Assets/Mob/Meshes/l_hand/"),
            ["Accessory"] = new("accessory_mesh", "res://Assets/Mob/Meshes/accessories/"),
        };
    
    // helper functions
    public static IReadOnlyList<float> GetFloatRange(float min = -1, float max = 1)
    {
        var result = new List<float>();
        for (int v = (int)(min * 10); v <= (int)(max * 10); v++)
            result.Add(v / 10.0f);
        return result;
    }
    private static IReadOnlyList<Color> GetColorsFromColorRange(Vector2? hue = null, Vector2? saturation = null, Vector2? brightness = null, Vector2? alpha = null)
    {
        // Use full range defaults if not provided
        var hRange = hue ?? Vector2.Zero;
        var sRange = saturation ?? Vector2.Zero;
        var vRange = brightness ?? Vector2.Zero;
        var aRange = alpha ?? Vector2.One;

        const int count = 10;
        var colors = new List<Color>(count);
        for (int i = 0; i < count; i++)
        {
            float w = count == 1 ? 0 : (float)i / (count - 1);
            float h = Mathf.Lerp(hRange.X, hRange.Y, w);
            float s = Mathf.Lerp(sRange.X, sRange.Y, w);
            float v = Mathf.Lerp(vRange.X, vRange.Y, w);
            float a = Mathf.Lerp(aRange.X, aRange.Y, w);
            colors.Add(Color.FromHsv(h, s, v, a));
        }
        return colors;
    }
    private static IReadOnlyDictionary<Gender, string[]> LoadMobNames(string jsonPath)
    {
        var dict = FileService.LoadJson<Dictionary<string, string[]>>(jsonPath) ?? new();
        return dict.ToDictionary(
            entry => Enum.Parse<Gender>(entry.Key),
            entry => entry.Value
        );
    }
    private static IReadOnlyDictionary<T, IReadOnlyList<NormInfo>> LoadNorms<T>(string jsonPath) where T : struct, Enum
    {
        var raw = FileService.LoadJson<Dictionary<string, List<NormInfo>>>(jsonPath) ?? new();
        var dict = raw.ToDictionary(
            entry => Enum.Parse<T>(entry.Key.Trim(), ignoreCase: true), IReadOnlyList<NormInfo> (entry) => entry.Value
        );
        return dict;
    }
    
}
