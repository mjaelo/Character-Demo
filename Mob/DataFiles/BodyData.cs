namespace CharacterDemo.Mob.DataFiles;

public record BodyData
{
    public MeshData HeadMesh = new();
    public MeshData EyeMesh = new();
    public MeshData LashesMesh = new();
    public MeshData HairMesh = new();
    public MeshData BeardMesh = new();
    public MeshData BrowMesh = new();
}

