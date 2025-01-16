extends MobData
class_name PlayerData


func _init(_mob_data:= MobData.new()):
	# MobData variables
	Utils.get_user_defined_variables(_mob_data).map(func (prop:String): self[prop] = _mob_data.get(prop))
	# PlayerData variables
	# TBD
