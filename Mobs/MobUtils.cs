using System;
using System.Linq;
using CharacterDemo.General;
using CharacterDemo.Mobs.DataFiles;
using CharacterDemo.Mobs.Scenes.MobScene;
using CharacterDemo.Mobs.Services.MobGeneration;
using Godot;
using Player = CharacterDemo.Mobs.Scenes.PlayerScene.Player;

namespace CharacterDemo.Mobs;

public static class MobUtils
{
    public static void SpawnOpponent(Node? parent = null)
    {
        var scene = ResourceLoader.Load<PackedScene>(MobConstants.MobScenePath);
        for (int x = -5; x < 5; x++)
        {
            var mob = (Mob)scene.Instantiate();
            mob.Transform = mob.Transform with { Origin = mob.Transform.Origin + new Vector3(x * 3, 0, 5) };
            var race = GeneralUtils.PickRandom(Enum.GetValues<MobEnums.MobRaces>());
            MobDataSetter.SetMobDataToMob(MobDataGetter.GetRandomMobData(race, MobEnums.MobTypes.Civilian), mob);
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
            MobDataGetter.GetBodyDataFieldValue(bodyData, fieldName).MeshColors = [hairColor];
            if (skeleton == null) continue;
            var mesh = MobGetter.GetMeshFromSkeleton(linkedName, skeleton);
            if (mesh != null) MobSetter.SetMeshColor(hairColor, mesh);
        }
    }
    
    public static void PropagateSkinColorData(EquipmentData eqData, Color skinColor, Skeleton3D? skeleton = null)
    {
        foreach (var meshName in MobConstants.MeshesWithSkin)
        {
            if (!MobConstants.EqMeshesInfo.TryGetValue(meshName, out var meshInfo)) continue;
            var fieldName = meshInfo.FieldName;
            var meshData = MobDataGetter.GetEqDataFieldValue(eqData, fieldName);
            if (meshData.MeshColors.Count == 0) continue;
            var colors = meshData.MeshColors.ToList();
            colors[0] = skinColor;
            meshData.MeshColors = colors;
            
            if (skeleton == null) continue;
            MeshInstance3D? mesh = MobGetter.GetMeshFromSkeleton(meshName, skeleton);
            if (mesh == null) continue;
            MobSetter.SetMeshColor(skinColor, mesh, 0);
        }
    }

    public static void AttachItemToBone(Node3D newSlot, Node3D item)
    {
        item.GetParent().RemoveChild(item);
        newSlot.AddChild(item);
        item.Position = Vector3.Zero;
        item.RotationDegrees = Vector3.Zero;
    }
}