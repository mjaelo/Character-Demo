using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.DataFiles;

public record MobData
{
    public MobRaces Race;
    public MobTypes Type;
    public string MobName = "";
    public Gender Gender;
    public BodyData BodyData = new();
    public EquipmentData EquipmentData = new();

    public MobData Duplicate()
    {
        return new MobData
        {
            Race = Race, Type = Type, MobName = MobName, Gender = Gender,
            BodyData = new BodyData
            {
                HeadMesh = BodyData.HeadMesh.Duplicate(),
                EyeMesh = BodyData.EyeMesh.Duplicate(),
                LashesMesh = BodyData.LashesMesh.Duplicate(),
                HairMesh = BodyData.HairMesh.Duplicate(),
                BeardMesh = BodyData.BeardMesh.Duplicate(),
                BrowMesh = BodyData.BrowMesh.Duplicate()
            },
            EquipmentData = new EquipmentData
            {
                TopMesh = EquipmentData.TopMesh.Duplicate(),
                BottomMesh = EquipmentData.BottomMesh.Duplicate(),
                ShoeMesh = EquipmentData.ShoeMesh.Duplicate(),
                HatMesh = EquipmentData.HatMesh.Duplicate(),
                RHandMesh = EquipmentData.RHandMesh.Duplicate(),
                LHandMesh = EquipmentData.LHandMesh.Duplicate(),
                AccessoryMesh = EquipmentData.AccessoryMesh.Duplicate()
            }
        };
    }
}