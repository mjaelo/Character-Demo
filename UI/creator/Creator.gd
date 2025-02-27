extends Control

var mob: Mob
var skeleton: Skeleton3D
var mob_data: MobData
var preset_node: TabBar

# pickers for mesh, color, shape
const menu_data := {
	"Body": {
		"Body": [false,true,["Body Shape","Body Mass","Body Muscles"]]
	},
	"Face": {
		"Eyes": [false,true,[]],
		"Eyelashes": [true,false,[]],
		"Body": [false,false,["Lips Width","Jaw Shape", "Face Length","Eye Lower Lid", "Eye Upper Lid","Eye Edge"]],
		"Accesory": [true,false,[]],
	},
	"Hair": {
		"Hair": [true,true,[]],
		"Brows":  [false,true,["Brow Thickness","Brow Length","Brow Inner","Brow Outer"]],
		"Beard": [true,true,[]]
	},
	"Clothes": {
		"Top": [true,true,[]],
		"Bottom": [true,true,[]],
		"Shoes": [true,true,[]],
		"Hat": [true,true,[]],
		"Right Hand": [true,false,[]],
		"Left Hand": [true,false,[]],
	},
}

# TODO
	# cant reproduse:
		# sometimes, preset race still incorrectly load (will be fixed when saved ti file?)
	# shoe has shape key for some reason
	# rename and better place water-try shader. delete test scene
	# hat:
		# use full_hide tag instead of full_hats variable
		# remove old hat hiders from scene and code
		# feather hat partly missing feather
	# PRESET:
		# save body to a file - copy solution from game? or even in a temporary method?

func _ready():
	skeleton = $"../Player/Mob/body/Armature/Skeleton3D"
	mob = $"../Player/Mob"
	preset_node = $TabContainer/Preset
	$"../Player/Controllers/CameraController/SpringArm3D".transform.origin.z += 2
	$CameraHeight.max_value = $"../Player/Controllers/CameraController/SpringArm3D".transform.origin.y
	$CameraHeight.value = $CameraHeight.max_value - 2
	
	UiUtils.disable_edit($"Start Game",!mob_data || !mob_data.mob_name)
	UiUtils.disable_edit(preset_node.get_node("ScrollContainer/VBoxContainer/Save Preset"),!mob_data || !mob_data.mob_name)
	give_player_control(false)
	
	$SetupCreator.setup(menu_data,skeleton)
	
	#load_all_resources()
	randomize_all()
	$TabContainer/Preset.mob_name_picker.text = ""

func give_player_control(has_control:bool):
	mob.set_process_unhandled_input(has_control)
	mob.set_physics_process(has_control)
	$"../Player/Controllers/CameraController".sensitivity = 5 if has_control else 1
	$"../Player/Controllers/CameraController".move_with_right_click = !has_control

func load_all_resources():
	var folders := []
	
	# get body folders
	folders.append_array(
		MobConstants.body_mesh_info.values().filter(
			func (mesh_info): return mesh_info.has("mesh_folder")
		).map(
			func (mesh_info): return mesh_info.mesh_folder
		)
	)
	
	# get clothes folders
	folders.append_array(
		MobConstants.eq_mesh_info.values().filter(
			func (mesh_info): return mesh_info.has("mesh_folder")
		).map(
			func (mesh_info): return mesh_info.mesh_folder
		)
	)
	
	# load recources
	for folder_path in folders:
		for file_name in Utils.get_file_names(folder_path):
			if Utils.cached_meshes_order.size() == Utils.cache_limit:
				break
			Utils.load_mesh(folder_path + file_name + ".tres")

func randomize_all():
	var gender:int = [0,2].pick_random()
	var type := MobConstants.MobTypes.Civilian#alues().pick_random()
	var race := MobConstants.MobRaces.Human
	mob_data = BodyGenerator.get_random_mob_data(skeleton,race,type,gender,"")
	BodyGenerator.set_mob_data_to_mob(mob_data,mob)
	update_all_pickers()

# MESH EDIT
# TODO works for meshes, but not clothes color and shape keys
func update_all_pickers():
	# preset data
	$TabContainer/Preset.mob_name_picker.text = mob_data.mob_name
	$TabContainer/Preset.mob_type_picker.picker.value = mob_data.type
	$TabContainer/Preset.mob_race_picker.picker.value = mob_data.race
	$TabContainer/Preset.mob_gender_picker.value = mob_data.gender
	
	# BODY 
	var body_data := mob_data.body_data
	var mesh_data_names := Utils.get_user_defined_variables(body_data)
	var mesh_names := MobConstants.body_mesh_info.keys()
	
	for i in mesh_data_names.size():
		var mesh_name:String = mesh_names[i]
		var mesh_data_name:String = mesh_data_names[i]
		var mesh_data: MeshData = body_data[mesh_data_name]
		set_mesh_data_to_pickers(mesh_data,mesh_name)
	
	# EQ
	var eq_data := mob_data.equipment_data
	var mesh_data_names2 := Utils.get_user_defined_variables(eq_data)
	var mesh_names2 := MobConstants.eq_mesh_info.keys()
	
	for i in mesh_data_names2.size():
		var mesh_name:String = mesh_names2[i]
		var mesh_data_name:String = mesh_data_names2[i]
		var mesh_data: MeshData = eq_data[mesh_data_name]
		set_mesh_data_to_pickers(mesh_data,mesh_name)

func set_mesh_data_to_pickers(mesh_data, mesh_name:String):
	for tab_name:String in menu_data.keys():
		if menu_data[tab_name].has(mesh_name):
			if mesh_data.mesh_name && menu_data[tab_name][mesh_name][0]:
				update_mesh_picker(mesh_data.mesh_name,tab_name,mesh_name,mesh_name)
			if mesh_data.mesh_color && menu_data[tab_name][mesh_name][1]:
				update_mesh_picker(mesh_data.mesh_color,tab_name,mesh_name,mesh_name+"Color")
			if mesh_data.mesh_shape && menu_data[tab_name][mesh_name][2]:
				var shape_names := MobUtils.get_shape_names_from_mesh(skeleton.get_node(mesh_name))
				if shape_names.size() != mesh_data.mesh_shape.size():
					print(mesh_name+" shapes differ in saved data and mesh")
					continue
				for j in mesh_data.mesh_shape.size():
					var shape_value:float = mesh_data.mesh_shape[j]
					var shape_name:String = shape_names[j]
					if menu_data[tab_name][mesh_name][2].has(shape_name):
						update_mesh_picker(shape_value,tab_name,mesh_name,shape_name)

func update_mesh_picker(value, tab_name:String, mesh_name:String, picker_name:String):
	# find picker
	var tab = $TabContainer.find_child(tab_name,true,false)
	if !tab:
		print("couldnt find tab ", tab_name)
		return
	tab = tab.get_children()[0].get_children()[0]
	var picker_node = tab.find_child(picker_name,true,false)
	
	# change picker value
	if picker_node:
		picker_node.set_value(value)
	else:
		print("\nCouldnt find "+picker_name+" in ", tab_name+" tab")

# Basic Creator Controls
func _on_randomize_all_pressed(node = $TabContainer.get_child($TabContainer.current_tab)):
	# randomize all tabs with limits
	if $TabContainer.current_tab == 0:
		randomize_all()
		return
	
	# randomize current tab without limits
	for child in node.get_children():
		# randomize slider
		if child.has_method("_on_random_button_pressed"):
			if !child.disabled && child.visible:
				child._on_random_button_pressed()
		elif child.get_children():
			_on_randomize_all_pressed(child)

func _on_camera_height_value_changed(value):
	$"../Player/Controllers/CameraController/SpringArm3D".transform.origin.y = value

func _on_start_game_pressed():
	print("starting game with ",mob_data.mob_name)
	
	# get mob data
	# get player data and set mob data to it
	# get new save data and set player data to it
	# start game with a given save data
	
	$"../".spawn_opponent()
	give_player_control(true)
	queue_free()
