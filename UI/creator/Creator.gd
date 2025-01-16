extends Control
var skeleton:Skeleton3D
var preset_node:TabBar

# pickers for mesh, color, shape
const menu_data := {
	"Body": {
		"Body": [false,true,["Body Shape","Body Mass","Body Muscles"]]
	},
	"Face": {
		"Eyes": [false,true,[]],
		"Eyelashes": [true,false,[]],
		"Body": [false,false,["Lips Width","Jaw Shape", "Face Length","Eye Lower Lid", "Eye Upper Lid","Eye Edge"]],
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
	# completely change logic based on diagram
	# shoe has shape key for some reason
	# rename and better place water-try shader. delete test scene
	# clean cache prints
	# hat:
		# use full_hide tag instead of full_hats variable
		# remove old hat hiders from scene and code
		# feather hat partly missing feather
	# PRESET:
		# save body to a file - copy solution from game?
		# make preset slider display character names
		# save eq_data too. its random now
	# make race change possible:
		# spirit: all glowy, small, always fall idle?
		# demon: red skin, extreme angry face, horns - model needed
		# ogre - shirtless, green skin, extreme fat, maybe yellow eyewhites, huge
		
		# edit eye white color
		# make many meshes empty able
		# edit char scale based on race
		# change visibility for skeleton


func _ready():
	PlayerData.new()
	
	UiUtils.disable_edit([$"Start Game"],true)
	give_player_control(false)
	$"../Player/Controllers/CameraController/SpringArm3D".transform.origin.z += 2
	$CameraHeight.max_value = $"../Player/Controllers/CameraController/SpringArm3D".transform.origin.y
	$CameraHeight.value = $CameraHeight.max_value - 2
	skeleton = $"../Player/Mob/body/Armature/Skeleton3D"
	preset_node = $TabContainer/Preset
	
	$SetupCreator.setup(menu_data,skeleton)
	
	#load_all_resources()
	randomize_all()

func give_player_control(has_control:bool):
	$"../Player/Mob".set_process_unhandled_input(has_control)
	$"../Player/Mob".set_physics_process(has_control)
	$"../Player/Controllers/CameraController".sensitivity = 5 if has_control else 1
	$"../Player/Controllers/CameraController".move_with_right_click = !has_control

func load_all_resources():
	var folders := []
	
	# get body folders
	folders.append_array(
		BodyGenerator.body_mesh_info.values().filter(
			func (mesh_info): return mesh_info.has("mesh_folder")
		).map(
			func (mesh_info): return mesh_info.mesh_folder
		)
	)
	
	# get clothes folders
	folders.append_array(
		BodyGenerator.eq_mesh_info.values().filter(
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
	var gender = [-1,1].pick_random()
	$TabContainer/Preset/ScrollContainer/VBoxContainer/GenderContainer/EditGender.value = gender
	preset_node.mob_type_picker.picker.value = 1
	preset_node.mob_type_picker.picker.value = 0
	var body_data = BodyGenerator.get_random_body(skeleton,gender)
	preset_node.set_body_data(body_data)
	var eq_data = BodyGenerator.get_random_equipment(skeleton,gender)
	preset_node.set_equipment_data(eq_data)

# MESH EDIT
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
		if picker_node.disabled:
			return
		if picker_node.picker is ColorPickerButton:
			picker_node.picker.color = value
			picker_node._on_picker_value_changed(value)
		else:
			# getting value id in list
			var val_id:= -1 #= picker_node.values.find(value,0) # i hate that that doesnt work. grrr.
			for val in picker_node.values.size():
				if picker_node.values[val] == value:
					val_id = val
					break
			
			# update picker value
			if val_id != -1:
				skeleton.get_node(mesh_name).visible = str(value) != "empty"
				if picker_node.picker.value != val_id:
					picker_node.picker.value = val_id # setting value id in list to picker
			else:
				if str(value) == "empty":
					skeleton.get_node(mesh_name).hide()
				else:
					print(str(value) + " " + picker_name + " not found in " + str(picker_node.values))
	else:
		print("\nCouldnt find "+picker_name+" in ", tab_name+" tab")

func update_linked_colors(value:Color,tab_name:String, linked_mesh_names:Array):
	for mesh_name in linked_mesh_names:
		update_mesh_picker(value,tab_name,mesh_name,mesh_name+"Color")

# Basic Creator Controls
func _on_randomize_all_pressed(node = $TabContainer.get_child($TabContainer.current_tab)):
	# randomize all tabs with limits
	if $TabContainer.current_tab == 0:
		randomize_all()
		return
	
	# randomize current tab without limits
	for child in node.get_children():
		# randomize slider
		if child.has_method("_on_random_button_pressed") && !child.disabled && child.visible:
			child._on_random_button_pressed()
		
		elif child.get_children():
			_on_randomize_all_pressed(child)

func _on_camera_height_value_changed(value):
	$"../Player/Controllers/CameraController/SpringArm3D".transform.origin.y = value

func _on_show_checkbox_toggled(toggled_on:bool,node_to_show:Control,mesh_name:String):
	node_to_show.visible = toggled_on
	if !toggled_on:
		update_mesh_picker(
			MobUtils.get_mesh_color(skeleton.get_node("Hair")),
			"Hair",mesh_name,mesh_name+"Color"
			)

func _on_start_game_pressed():
	print("starting game with ",preset_node.mob_name)
	
	# get body data
	# get equipment data
	# get mob data and set body, eq and name to it
	# get player data and set mob data to it
	# get new save data and set player data to it
	# start game with a given save data
	
	$"../".spawn_opponent()
	give_player_control(true)
	queue_free()
