using System;
using System.Collections.Generic;
using System.Linq;
using CharacterDemo.General;
using CharacterDemo.General.Services;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.Scenes.Player;
using CharacterDemo.Mob.Services.MobGeneration;
using Godot;

namespace CharacterDemo.Mob;

public static class MobUtils // TODO move GET SET ADJUST functions to MobGeneration services?
{
    private static readonly Dictionary<string, List<string>> CachedMeshShapeNames = new(); // TODO caches shouldnt be kept here

    //  SET MESH DATA 
    public static void SetMeshFile(string fileName, MeshInstance3D meshInstance, string path)
    {
        var filePath = path + fileName + ".tres";
        var newMesh = FileService.LoadMesh(filePath);
        if (newMesh != null)
        {
            meshInstance.Show();
            meshInstance.Mesh = newMesh;
        }
        else
        {
            meshInstance.Hide();            
            if (fileName is not ("empty" or "")) GD.Print(filePath, " not found");
        }

        // update hair hider and sword col shape
        if (MobConstants.HairAdjustingNames.Contains(meshInstance.Name.ToString())) AdjustHairHider((Skeleton3D)meshInstance.GetParent());

        if (meshInstance.Name != "Sword") return;
        var swordCollision = meshInstance.GetNode<CollisionShape3D>("StaticBody3D/CollisionShape3D");
        swordCollision.Shape = meshInstance.Visible
            ? meshInstance.Mesh.CreateConvexShape()
            : new SphereShape3D { Radius = 10 };
    }

    public static void SetSkeletonShapeKey(float value, string shapeName, Skeleton3D skel)
    {
        foreach (var child in skel.GetChildren().OfType<MeshInstance3D>())
            if (child.GetBlendShapeCount() > 0)
                SetMeshShapeKey(value, shapeName, child);

        if (MobConstants.HipMovers.Contains(shapeName))
            AdjustHip(skel);
    }

    private static void AdjustHairHider(Skeleton3D skeleton)
    {
        var hatMesh = skeleton.GetNode<MeshInstance3D>("Hat");
        var hairMesh = skeleton.GetNode<MeshInstance3D>("Hair");
        var hiderNode = skeleton.GetNode<BoneAttachment3D>("HairHider");
        var hairMaterial = (StandardMaterial3D?)hairMesh.GetActiveMaterial(0);
        var mob = skeleton.GetNode<Scenes.Mob.Mob>("../../../");
        if (mob.BodyData == new BodyData() || mob.EquipmentData == new EquipmentData()) return;

        bool isHairBald = mob.BodyData.HairMesh.MeshFile == "empty";
        bool hasHat = mob.EquipmentData.HatMesh.MeshFile is not ("empty" or "");
        bool isFullHat = MobConstants.FullHats.Any(h => mob.EquipmentData.HatMesh.MeshFile == h);
        hairMesh.Visible = !isHairBald && !(hasHat && isFullHat);

        if (hasHat && hairMesh.Visible)
        {
            hiderNode.Show();
            var baseMesh = hiderNode.GetNode<MeshInstance3D>("Manager/HatHairHider");
            var newHiderNode = hiderNode.GetNode<Node3D>("Manager/NewHiders");

            if (hairMaterial != null)
            {
                hairMaterial.Transparency = BaseMaterial3D.TransparencyEnum.Alpha;
                hairMaterial.RenderPriority = -1;
            }

            baseMesh.Mesh = hatMesh.Mesh;
            var baseMat = baseMesh.GetActiveMaterial(0);
            if (baseMat != null) baseMat.RenderPriority = 2;

            foreach (MeshInstance3D hatHider in newHiderNode.GetChildren().OfType<MeshInstance3D>())
                hatHider.Mesh = hatMesh.Mesh;

            if (newHiderNode.GetChildCount() != 0) return;
            for (int i = 0; i < 100; i++)
            {
                var dup = (MeshInstance3D)baseMesh.Duplicate();
                dup.Position += new Vector3(0, i * 0.1f, 0);
                newHiderNode.AddChild(dup);
            }
        }
        else
        {
            hiderNode.Hide();
            if (hairMaterial != null) hairMaterial.Transparency = BaseMaterial3D.TransparencyEnum.Disabled;
        }
    }

    private static void AdjustHip(Skeleton3D skel)
    {
        var hipManager = skel.GetNode<Node3D>("Hip/HipContainer");
        var bodyMesh = skel.GetNode<MeshInstance3D>("Top");
        if (bodyMesh.Mesh is not ArrayMesh arrayMesh || arrayMesh.GetBlendShapeCount() == 0)
            return; // Mesh has no blend shapes (e.g., skeleton variants)
        
        float addedAmount = 0;
        for (int i = 0; i < MobConstants.HipMovers.Length; i++)
        {
            if (i >= arrayMesh.GetBlendShapeCount()) break; // Safety check
            var shapeId = arrayMesh.GetBlendShapeName(i) == MobConstants.HipMovers[i] ? i : -1;
            if (shapeId < 0) continue;
            float val = bodyMesh.GetBlendShapeValue(shapeId);
            float multiplier = i == 0 ? 4f : 7f;
            addedAmount += val * multiplier;
        }

        var origin = hipManager.Transform.Origin;
        origin.X = 17 + addedAmount;
        hipManager.Transform = hipManager.Transform with { Origin = origin };
    }

    private static void SetMeshShapeKey(float value, string shapeName, MeshInstance3D mesh)
    {
        int id = mesh.FindBlendShapeByName(shapeName);
        if (id > -1) mesh.SetBlendShapeValue(id, value);
    }

    public static void SetMeshColor(Color value, MeshInstance3D meshInstance, int materialNr = -1)
    {
        materialNr = materialNr >= 0 ? materialNr : GetMainMaterial(meshInstance);
        if (meshInstance.Mesh == null || materialNr >= meshInstance.Mesh.GetSurfaceCount()
                                      || (meshInstance.MaterialOverride ?? meshInstance.Mesh.SurfaceGetMaterial(materialNr)) is not StandardMaterial3D material) return;
        
        material = (StandardMaterial3D)material.Duplicate();
        material.AlbedoColor = value;
        if (meshInstance.MaterialOverride != null)
            meshInstance.MaterialOverride = material;
        else
            meshInstance.SetSurfaceOverrideMaterial(materialNr, material);

    }

    public static void PropagateSkinColorData(EquipmentData eqData, Color skinColor, Skeleton3D? skeleton = null)
    {
        foreach (var meshName in MobConstants.MeshesWithSkin)
        {
            if (!MobConstants.EqMeshesInfo.ContainsKey(meshName)) continue;
            var fieldName = MobConstants.EqMeshesInfo[meshName].FieldName;
            var meshData = GetEqDataFieldValue(eqData, fieldName);
            if (meshData.MeshColors.Count == 0) continue;
            var colors = meshData.MeshColors.ToList();
            colors[0] = skinColor;
            meshData.MeshColors = colors;
            
            if (skeleton == null) continue;
            MeshInstance3D? skelMesh = GetMeshFromSkeleton(meshName, skeleton);
            if (skelMesh == null) continue;
            SetMeshColor(skinColor, skelMesh, 0);
        }
    }

    //  GET MESH DATA 
    public static int GetMainMaterial(MeshInstance3D meshInstance) // TODO add as a property toMobMeshInfo?
    {
        if (meshInstance.Name == "Eyes") return 1;
        if (meshInstance.Name == "Top") return 1;
        if (meshInstance.Name == "Bottom") return 1;
        return 0;
    }

    public static MeshInstance3D? GetMeshFromSkeleton(string meshName, Skeleton3D skeleton)
    {
        if (MobConstants.HandNames[0] == meshName)
            return skeleton.GetNode<Node3D>("Hip").GetChild(0).GetChild<MeshInstance3D>(0);
        return MobConstants.HandNames[1] == meshName
            ? skeleton.GetNode<Node3D>("Back").GetChild(0).GetChild<MeshInstance3D>(0)
            : skeleton.GetNodeOrNull<MeshInstance3D>(meshName);
    }

    public static IReadOnlyList<string> GetShapeNamesFromMesh(Mesh? mesh)
    {
        if (mesh is not ArrayMesh arrayMesh) return [];
        var path = arrayMesh.ResourcePath;
        if (CachedMeshShapeNames.TryGetValue(path, out var names)) return names;
        names = Enumerable
            .Range(0, arrayMesh.GetBlendShapeCount())
            .Select(i => arrayMesh.GetBlendShapeName(i).ToString())
            .ToList();
        CachedMeshShapeNames[path] = names;
        return names;
    }

    // GENERAL MOB HELPERS
    public static void SpawnOpponent(Node? parent = null)
    {
        var scene = ResourceLoader.Load<PackedScene>(MobConstants.MobScenePath);
        for (int x = -5; x < 5; x++)
        {
            var mob = (Scenes.Mob.Mob)scene.Instantiate();
            mob.Transform = mob.Transform with { Origin = mob.Transform.Origin + new Vector3(x * 3, 0, 5) };
            var race = GeneralUtils.PickRandom(Enum.GetValues<MobEnums.MobRaces>());
            MobSetter.SetMobDataToMob(MobGetter.GetRandomMobData(race, MobEnums.MobTypes.Civilian), mob);
            (parent ?? mob.GetTree().CurrentScene).AddChild(mob);
        }
    }

    public static void TogglePlayerControl(bool hasControl, Player mob)
    {
        mob.CameraManager.IsCreatorMode = !hasControl;
        mob.SetProcessUnhandledInput(hasControl);
        mob.SetPhysicsProcess(hasControl);
    }

    public static void PropagateHairColor(BodyData bodyData, Skeleton3D? skeleton = null)
    {
        if (bodyData.HairMesh == new MeshData()) return;
        var hairColor = bodyData.HairMesh.MeshColors[0];
        foreach (var linkedName in MobConstants.HairLinkedNames)
        {
            string fieldName = MobConstants.BodyMeshesInfo[linkedName].FieldName;
            GetBodyDataFieldValue(bodyData, fieldName).MeshColors = [hairColor];
            if (skeleton == null) continue;
            var mesh = GetMeshFromSkeleton(linkedName, skeleton);
            if (mesh != null) SetMeshColor(hairColor, mesh);
        }
    }
    
    // Helpers to set mesh data on data objects by field name TODO are there no better options?
    public static void SetDataToBodyDataField(BodyData bodyData, string fieldName, MeshData meshData)
    {
        switch (fieldName)
        {
            case "head_mesh": bodyData.HeadMesh = meshData; break;
            case "eye_mesh": bodyData.EyeMesh = meshData; break;
            case "lashes_mesh": bodyData.LashesMesh = meshData; break;
            case "hair_mesh": bodyData.HairMesh = meshData; break;
            case "beard_mesh": bodyData.BeardMesh = meshData; break;
            case "brow_mesh": bodyData.BrowMesh = meshData; break;
        }
    }

    public static void SetDataToEqDataField(EquipmentData eqData, string fieldName, MeshData meshData)
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

    public static MeshData GetBodyDataFieldValue(BodyData bodyData, string fieldName) => fieldName switch
    {
        "head_mesh" => bodyData.HeadMesh,
        "eye_mesh" => bodyData.EyeMesh,
        "lashes_mesh" => bodyData.LashesMesh,
        "hair_mesh" => bodyData.HairMesh,
        "beard_mesh" => bodyData.BeardMesh,
        "brow_mesh" => bodyData.BrowMesh,
        _ => new MeshData()
    };

    public static MeshData GetEqDataFieldValue(EquipmentData eqData, string fieldName) => fieldName switch
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
    
    public static void AttachItemToBone(Node3D newSlot, Node3D item)
    {
        item.GetParent().RemoveChild(item);
        newSlot.AddChild(item);
        item.Position = Vector3.Zero;
        item.RotationDegrees = Vector3.Zero;
    }
}