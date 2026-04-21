extends Resource
class_name MobData

const FIELD_NAMES := ["race", "type", "mob_name", "gender", "body_data", "equipment_data"]

var race: int = 0
var type: int = 0
var mob_name: String = ""
var gender: int = 0
var body_data: BodyData
var equipment_data: EquipmentData

func _init(_race := MobConstants.MobRaces.Human, _type := MobConstants.MobTypes.Civilian, _mob_name := "", _gender := MobConstants.Gender.NonBin,
		_body_data := BodyData.new(), _equipment_data := EquipmentData.new()):
	race = _race
	type = _type
	mob_name = _mob_name
	gender = _gender
	body_data = _body_data
	equipment_data = _equipment_data
