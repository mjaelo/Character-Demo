using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.DataFiles;

public class MobData(
    MobRaces race = MobRaces.Human,
    MobTypes type = MobTypes.Civilian,
    string mobName = "",
    Gender gender = Gender.NonBin,
    BodyData? bodyData = null,
    EquipmentData? equipmentData = null)
{
    public MobRaces Race = race;
    public MobTypes Type = type;
    public string MobName = mobName;
    public Gender Gender = gender;
    public BodyData BodyData = bodyData ?? new BodyData();
    public EquipmentData EquipmentData = equipmentData ?? new EquipmentData();
}