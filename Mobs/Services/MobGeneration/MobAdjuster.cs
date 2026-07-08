using System.Linq;
using CharacterDemo.Mobs.DataFiles;
using CharacterDemo.Mobs.Scenes.MobScene;
using Godot;

namespace CharacterDemo.Mobs.Services.MobGeneration;

///  ADJUST (keep valid, re-randomize invalid) 
public static class MobAdjuster
{
    public static void AdjustHairHider(Skeleton3D skeleton)
    {
        var hatMesh = skeleton.GetNode<MeshInstance3D>("Hat");
        var hairMesh = skeleton.GetNode<MeshInstance3D>("Hair");
        var hiderNode = skeleton.GetNode<BoneAttachment3D>("HairHider");
        var hairMaterial = (StandardMaterial3D?)hairMesh.GetActiveMaterial(0);
        var mob = skeleton.GetNode<Mob>("../../../");
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

    public static void AdjustHip(Skeleton3D skeleton)
    {
        var hipManager = skeleton.GetNode<Node3D>("Hip/HipContainer");
        var bodyMesh = skeleton.GetNode<MeshInstance3D>("Top");
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
    
}

