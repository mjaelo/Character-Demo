extends MobData
class_name PlayerData


func _init(_mob_data := MobData.new()):
	for prop in MobData.FIELD_NAMES:
		self[prop] = _mob_data.get(prop)
