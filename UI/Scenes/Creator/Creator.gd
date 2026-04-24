extends Control
class_name Creator

@onready var tab_container := $TabContainer
@onready var preset_tab:PresetTab = $TabContainer/Preset
@onready var start_button := $"CreatorCameraManager/Start Game"
var player:Player
var skeleton: Skeleton3D
var mob_data:= MobData.new()
var tab_builder: TabBuilder

func initialize(_player: Player, _skeleton: Skeleton3D):
	player = _player
	MobUtils.toggle_player_control(false, player)
	skeleton = _skeleton
	tab_builder = TabBuilder.new(_skeleton, mob_data)
	preset_tab.initialize(self)
	
	# disable UI edit
	UIUtils.disable_edit(start_button,!mob_data || !mob_data.mob_name)
	UIUtils.disable_edit(preset_tab.get_node("ScrollContainer/VBoxContainer/Preset Handler/Save Preset"),!mob_data || !mob_data.mob_name)
	UIUtils.disable_edit(preset_tab.get_node("ScrollContainer/VBoxContainer/Preset Handler/Delete Preset"),true)
	
	# create tabs with pickers
	for tab_name:String in UIConstants.menu_data.keys():
		tab_container.add_child(tab_builder.create_tab(UIConstants.menu_data[tab_name], tab_name))
	
	# apply random mob data
	randomize_creator_values()
	
func start_game():
	print("starting game with ",mob_data.mob_name)
	
	FileUtils.deserialize_and_save(preset_tab.presets, "res://UI/Scenes/Creator/", "preset.json")
	
	# get mob data
	# get player data and set mob data to it
	# get new save data and set player data to it
	# start game with a given save data
	
	MobUtils.spawn_opponent(get_parent())
	MobUtils.toggle_player_control(true,player)
	queue_free()

# UTILS update pickers
func randomize_creator_values():
	var type: int = MobConstants.MobTypes.Civilian if !mob_data else -1
	var race: int = MobConstants.MobRaces.Human if !mob_data else -1
	mob_data = MobGetter.get_random_mob_data(skeleton,race,type)
	mob_data.mob_name = ""
	tab_builder.mob_data = mob_data
	MobSetter.set_mob_data_to_mob(mob_data, player)
	preset_tab.set_mob_data_to_preset_pickers(mob_data)
	set_mob_data_to_pickers(mob_data)

func randomize_all():
	randomize_creator_values()

func update_all_pickers():
	tab_builder.mob_data = mob_data
	preset_tab.set_mob_data_to_preset_pickers(mob_data)
	set_mob_data_to_pickers(mob_data)

func set_mob_data_to_pickers(_mob_data: MobData):
	for mesh_name:String in MobConstants.BODY_MESHES_INFO.keys():
		var mesh_info: MobMeshInfo = MobConstants.BODY_MESHES_INFO[mesh_name]
		var field_name: String = mesh_info.field_name
		var mesh_data: MeshData = _mob_data.body_data[field_name]
		set_mesh_data_to_pickers(mesh_data,mesh_name)
	
	for mesh_name:String in MobConstants.EQ_MESHES_INFO.keys():
		var mesh_info: MobMeshInfo = MobConstants.EQ_MESHES_INFO[mesh_name]
		var field_name: String = mesh_info.field_name
		var mesh_data: MeshData = _mob_data.equipment_data[field_name]
		set_mesh_data_to_pickers(mesh_data,mesh_name)

func set_mesh_data_to_pickers(mesh_data:MeshData, mesh_name:String):
	for tab_name: String in UIConstants.menu_data.keys():
		var picker_info: MeshPickerInfo = null
		for info: MeshPickerInfo in UIConstants.menu_data[tab_name]:
			if info.mesh_name == mesh_name:
				picker_info = info
				break
		if !picker_info:
			continue
		if mesh_data.mesh_file && picker_info.has_file_picker:
			find_picker_and_set_value(mesh_data.mesh_file, tab_name, mesh_name)
		if mesh_data.has_color() && picker_info.has_color_picker:
			find_picker_and_set_value(mesh_data.mesh_color, tab_name, mesh_name + "Color")
		if mesh_data.mesh_shape && picker_info.has_shape_picker:
			var mesh_instance := skeleton.get_node(mesh_name) if skeleton.has_node(mesh_name) else null
			if !mesh_instance:
				continue
			var shape_names := MobUtils.get_shape_names_from_mesh(mesh_instance.mesh)
			if shape_names.size() != mesh_data.mesh_shape.size():
				print(mesh_name + " shapes differ in saved data and mesh")
				continue
			for j in mesh_data.mesh_shape.size():
				var shape_value: float = float(mesh_data.mesh_shape[j])
				var shape_name: String = shape_names[j]
				find_picker_and_set_value(shape_value, tab_name, shape_name)

func find_picker_and_set_value(value, tab_name:String, picker_name:String) -> void:
	# find picker
	var tab: Node = tab_container.find_child(tab_name,true,false)
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
