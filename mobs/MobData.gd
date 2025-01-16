extends Node
class_name MobData

var race: int
var type: int
var mob_name:String
var gender: int
var body_data: BodyData
var equipment_data: EquipmentData


func _init(_race:=MobConstants.MobRaces.Human, _type:=MobConstants.MobTypes.Civilian, _mob_name:="NPC", _gender:=MobConstants.Gender.NonBin,
		_body_data:= BodyData.new(),_equipment_data:= EquipmentData.new()):
	race = _race
	type = _type
	mob_name = _mob_name
	gender = _gender
	body_data = _body_data
	equipment_data = _equipment_data
