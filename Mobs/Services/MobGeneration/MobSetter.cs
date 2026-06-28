using System.Linq;
using CharacterDemo.General.Services;
using CharacterDemo.Mobs.DataFiles;
using CharacterDemo.Mobs.Scenes.MobScene;
using Godot;

namespace CharacterDemo.Mobs.Services.MobGeneration;

public static class MobSetter
{
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
        if (MobConstants.HairAdjustingNames.Contains(meshInstance.Name.ToString())) MobAdjuster.AdjustHairHider((Skeleton3D)meshInstance.GetParent());

        if (meshInstance.Name != "Sword") return;
        var swordCollision = meshInstance.GetNode<CollisionShape3D>("StaticBody3D/CollisionShape3D");
        swordCollision.Shape = meshInstance.Visible
            ? meshInstance.Mesh.CreateConvexShape()
            : new SphereShape3D { Radius = 10 };
    }

    public static void SetSkeletonShapeKey(float value, string shapeName, Skeleton3D skeleton)
    {
        foreach (var child in skeleton.GetChildren().OfType<MeshInstance3D>())
            if (child.GetBlendShapeCount() > 0)
                SetMeshShapeKey(value, shapeName, child);

        if (MobConstants.HipMovers.Contains(shapeName))
            MobAdjuster.AdjustHip(skeleton);
    }
    
    public static void SetMeshColor(Color value, MeshInstance3D meshInstance, int materialNr = -1)
    {
        materialNr = materialNr >= 0 ? materialNr : MobGetter.GetMainMaterial(meshInstance);
        if (meshInstance.Mesh == null || materialNr >= meshInstance.Mesh.GetSurfaceCount()
                                      || (meshInstance.MaterialOverride ?? meshInstance.Mesh.SurfaceGetMaterial(materialNr)) is not StandardMaterial3D material) return;
        
        material = (StandardMaterial3D)material.Duplicate();
        material.AlbedoColor = value;
        if (meshInstance.MaterialOverride != null)
            meshInstance.MaterialOverride = material;
        else
            meshInstance.SetSurfaceOverrideMaterial(materialNr, material);

    }
    
    private static void SetMeshShapeKey(float value, string shapeName, MeshInstance3D mesh)
    {
        int id = mesh.FindBlendShapeByName(shapeName);
        if (id > -1) mesh.SetBlendShapeValue(id, value);
    }
}