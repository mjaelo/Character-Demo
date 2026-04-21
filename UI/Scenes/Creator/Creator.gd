extends SetupCreator
class_name Creator

@onready var mob:Player
@onready var preset_node := $TabContainer/Preset
@onready var start_button := $"RightCreator/Start Game"


func init(_mob: Player, _skeleton: Skeleton3D):
	mob = _mob
	skeleton = _skeleton
	
	# disable UI edit
	UIUtils.disable_edit(start_button,!mob_data || !mob_data.mob_name)
	UIUtils.disable_edit(preset_node.get_node("ScrollContainer/VBoxContainer/Preset Handler/Save Preset"),!mob_data || !mob_data.mob_name)
	UIUtils.disable_edit(preset_node.get_node("ScrollContainer/VBoxContainer/Preset Handler/Delete Preset"),true)
	
	# create pickers
	setup()
	
	# apply random mob data
	randomize_all()
	mob_data.mob_name = ""
	preset_node.mob_name_picker.text = ""

func toggle_player_control(has_control:bool):
	mob.set_process_unhandled_input(has_control)
	mob.set_physics_process(has_control)

func randomize_all():
	var type: int = MobConstants.MobTypes.Civilian if !mob_data else -1
	var race: int = MobConstants.MobRaces.Human if !mob_data else -1
	mob_data = MobGenerator.get_random_mob_data(skeleton,race,type)
	MobGenerator.set_mob_data_to_mob(mob_data,mob)
	update_all_pickers()

# MESH EDIT
func update_all_pickers():
	# preset data
	preset_node.mob_name_picker.text = mob_data.mob_name
	preset_node.mob_type_picker.picker.value = mob_data.type
	preset_node.mob_race_picker.picker.value = mob_data.race
	preset_node.mob_gender_picker.value = mob_data.gender
	
	# BODY, EQ
	for data_type in ["body_data","equipment_data"]:
		var body_eq_data = mob_data[data_type]
		var mesh_data_names: Array = BodyData.FIELD_NAMES if data_type == "body_data" else EquipmentData.FIELD_NAMES
		var mesh_names:Array = MobConstants["body_mesh_info" if data_type == "body_data" else "eq_mesh_info"].keys()
		
		for i in mesh_data_names.size():
			var mesh_name:String = mesh_names[i]
			var mesh_data_name:String = mesh_data_names[i]
			var mesh_data: MeshData = body_eq_data[mesh_data_name]
			set_mesh_data_to_pickers(mesh_data,mesh_name)

func set_mesh_data_to_pickers(mesh_data:MeshData, mesh_name:String):
	for tab_name:String in UIConstants.menu_data.keys():
		if UIConstants.menu_data[tab_name].has(mesh_name):
			if mesh_data.mesh_name && UIConstants.menu_data[tab_name][mesh_name][0]:
				update_mesh_picker(mesh_data.mesh_name,tab_name,mesh_name,mesh_name)
			if mesh_data.mesh_color && UIConstants.menu_data[tab_name][mesh_name][1]:
				update_mesh_picker(mesh_data.mesh_color,tab_name,mesh_name,mesh_name+"Color")
			if mesh_data.mesh_shape && UIConstants.menu_data[tab_name][mesh_name][2]:
				var shape_names := MobUtils.get_shape_names_from_mesh(skeleton.get_node(mesh_name).mesh)
				if shape_names.size() != mesh_data.mesh_shape.size():
					print(mesh_name+" shapes differ in saved data and mesh")
					continue
				for j in mesh_data.mesh_shape.size():
					var shape_value:float = float(mesh_data.mesh_shape[j])
					var shape_name:String = shape_names[j]
					if UIConstants.menu_data[tab_name][mesh_name][2].has(shape_name):
						update_mesh_picker(shape_value,tab_name,mesh_name,shape_name)

func update_mesh_picker(value, tab_name:String, mesh_name:String, picker_name:String) -> void:
	# find picker
	var tab: Node = $TabContainer.find_child(tab_name,true,false)
	if !tab:
		print("couldnt find tab ", tab_name)
		return
	tab = tab.get_children()[0].get_children()[0]
	var picker_node: Node = tab.find_child(picker_name,true,false)
	
	# change picker value
	if picker_node:
		picker_node.set_value(value)
	else:
		print("\nCouldnt find "+picker_name+" in ", tab_name+" tab")

func start_game():
	print("starting game with ",mob_data.mob_name)
	
	FileUtils.deserialize_and_save(preset_node.presets, "res://UI/Scenes/Creator/", "preset.json")
	
	# get mob data
	# get player data and set mob data to it
	# get new save data and set player data to it
	# start game with a given save data
	
	MobUtils.spawn_opponent(get_parent())
	toggle_player_control(true)
	queue_free()
