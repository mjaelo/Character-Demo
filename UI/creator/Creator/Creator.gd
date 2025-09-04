extends Control

@onready var mob := $"../Player/Mob"
@onready var skeleton := $"../Player/Mob/body/Armature/Skeleton3D"
@onready var preset_node := $TabContainer/Preset
@onready var start_button := $"RightCreator/Start Game"

var mob_data: MobData

# tab name > mesh name > pickers for mesh, color, shape
const menu_data := {
	"Body": {
		"Body": [false,true,["Body Shape","Body Mass","Body Muscles"]]
	},
	"Face": {
		"Eyes": [false,true,[]],
		"Eyelashes": [true,false,[]],
		"Head": [false,false,["Lips Width","Lips Thickness","Lip Corner","Jaw Shape", "Face Length","Eye Lower Lid Height", "Eye Upper Lid Height","Eye Edge Height"]],
		"Accessory": [true,false,[]],
	},
	"Hair": {
		"Hair": [true,true,[]],
		"Brows":  [false,true,["Brow Thickness","Brow Inner Height","Brow Outer Height"]],
		"Beard": [true,true,[]]
	},
	"Clothes": {
		"Top": [true,true,[]],
		"Bottom": [true,true,[]],
		"Feet": [true,true,[]],
		"Hat": [true,true,[]],
		"Right Hand": [true,false,[]],
		"Left Hand": [true,false,[]],
	},
}

func _ready():
	# disable UI edit
	UiUtils.disable_edit(start_button,!mob_data || !mob_data.mob_name)
	UiUtils.disable_edit(preset_node.get_node("ScrollContainer/VBoxContainer/Preset Handler/Save Preset"),!mob_data || !mob_data.mob_name)
	UiUtils.disable_edit(preset_node.get_node("ScrollContainer/VBoxContainer/Preset Handler/Delete Preset"),true)
	
	# take away player control
	give_player_control(false)
	
	# create pickers
	$SetupCreator.setup(menu_data,skeleton)
	
	#load_all_resources()
	
	# apply random mob data
	randomize_all()
	mob_data.mob_name = ""
	preset_node.mob_name_picker.text = ""

func give_player_control(has_control:bool):
	mob.set_process_unhandled_input(has_control)
	mob.set_physics_process(has_control)

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
	var type = MobConstants.MobTypes.Civilian if !mob_data else -1
	var race = MobConstants.MobRaces.Human if !mob_data else -1
	mob_data = MobGenerator.get_random_mob_data(skeleton,race,type)
	MobGenerator.set_mob_data_to_mob(mob_data,mob)
	var mesh:MeshInstance3D = skeleton.get_node("Top")
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
		var mesh_data_names := Utils.get_user_defined_variables(body_eq_data)
		var mesh_names:Array = MobConstants["body_mesh_info" if data_type == "body_data" else "eq_mesh_info"].keys()
		
		for i in mesh_data_names.size():
			var mesh_name:String = mesh_names[i]
			var mesh_data_name:String = mesh_data_names[i]
			var mesh_data: MeshData = body_eq_data[mesh_data_name]
			set_mesh_data_to_pickers(mesh_data,mesh_name)

func set_mesh_data_to_pickers(mesh_data:MeshData, mesh_name:String):
	for tab_name:String in menu_data.keys():
		if menu_data[tab_name].has(mesh_name):
			if mesh_data.mesh_name && menu_data[tab_name][mesh_name][0]:
				update_mesh_picker(mesh_data.mesh_name,tab_name,mesh_name,mesh_name)
			if mesh_data.mesh_color && menu_data[tab_name][mesh_name][1]:
				update_mesh_picker(mesh_data.mesh_color,tab_name,mesh_name,mesh_name+"Color")
			if mesh_data.mesh_shape && menu_data[tab_name][mesh_name][2]:
				var shape_names := MobUtils.get_shape_names_from_mesh(skeleton.get_node(mesh_name).mesh)
				if shape_names.size() != mesh_data.mesh_shape.size():
					print(mesh_name+" shapes differ in saved data and mesh")
					continue
				for j in mesh_data.mesh_shape.size():
					var shape_value:float = float(mesh_data.mesh_shape[j])
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

func start_game():
	print("starting game with ",mob_data.mob_name)
	
	FileUtils.deserialize_and_save(preset_node.presets, "res://UI/creator/", "preset.json")
	
	# get mob data
	# get player data and set mob data to it
	# get new save data and set player data to it
	# start game with a given save data
	
	$"../".spawn_opponent()
	give_player_control(true)
	queue_free()
