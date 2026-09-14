namespace CharacterDemo.Mobs.DataFiles;

public record EquipmentData
{
    public MeshData TopMesh = new();
    public MeshData BottomMesh = new();
    public MeshData ShoeMesh = new();
    public MeshData HatMesh = new();
    public MeshData RHandMesh = new();
    public MeshData LHandMesh = new();
    public MeshData AccessoryMesh = new();
}

