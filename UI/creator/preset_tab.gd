extends TabBar

const name_list := ["Jeff", "Anabelle", "Alex"] # TODO () connect with mob_dict
const override_warning := "Overriding preset with the same name"

var parent_node:Control
var save_button_node:Button

var preset_picker:HBoxContainer
var mob_type_picker:HBoxContainer
var mob_race_picker:HBoxContainer
var mob_gender_picker:HSlider

var presets := [] # TODO () make into file and read from it

var mob_name := "Hero"


func _ready():
	parent_node = $"../../"
	save_button_node = $"ScrollContainer/VBoxContainer/Save Preset"
	mob_gender_picker = $ScrollContainer/VBoxContainer/GenderContainer/EditGender
	
	# setup preset picker
	presets = [] # TODO () read saved presets from when connected to game
	preset_picker = $ScrollContainer/VBoxContainer/Preset
	preset_picker.init(presets, "Preset") # setup slider with loaded presets
	preset_picker.variable_changed.connect(set_body_data)
	
	# setup type picker TODO () remove when connected to game
	mob_type_picker = $ScrollContainer/VBoxContainer/MobType
	mob_type_picker.init(MobConstants.MobTypes.keys(), "Mob Type")
	mob_type_picker.variable_changed.connect(func (_v):_on_random_clothes_pressed())
	
	# setup race picker TODO () remove when connected to game
	mob_race_picker = $ScrollContainer/VBoxContainer/Race
	mob_race_picker.init(MobConstants.MobRaces.keys(), "Race")
	mob_race_picker.variable_changed.connect(race_changed)

func _on_save_preset_pressed():
	# get body data into BodyData object
	var body_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Body"))
	var eye_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Eyes"))
	var lashes_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Eyelashes"))
	
	var hair_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Hair"))
	var beard_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Beard"))
	var brow_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Brows"))
	
	var top_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Top"))
	var bottom_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Bottom"))
	var shoe_mesh := mesh_to_mesh_data(parent_node.skeleton.get_node("Shoes"))
	var accessory_mesh := MeshData.new() # TODO ()
	
	var body_data := BodyData.new(
		body_mesh, eye_mesh,lashes_mesh,
		hair_mesh, beard_mesh, brow_mesh
	)
	var eq_data := EquipmentData.new(
		top_mesh, bottom_mesh, shoe_mesh, accessory_mesh
	)
	
	# save body_data into saved_presets.json file TODO () use eq_data too
	presets.append(body_data) # TODO () in game, you can use real methods
	
	# update slider
	if !preset_picker.picker:
		preset_picker.init(presets, "Preset")
	else:
		preset_picker.picker.max_value = presets.size()-1
		preset_picker.picker.value = presets.size()-1
		preset_picker.values = presets
	
	UiUtils.button_show_warning(save_button_node,override_warning)

func mesh_to_mesh_data(mesh:MeshInstance3D) -> MeshData:
	var color: Color = MobUtils.get_mesh_color(mesh)
	var mesh_name := mesh.mesh.resource_path.split("/")[-1].trim_suffix(".tres") if mesh.visible else "empty"
	var shapes := []
	for i in mesh.get_blend_shape_count():
		var value = int(mesh.get_blend_shape_value(i)*10) / 10.0 # TODO but what if its 2 spaces after comma?
		shapes.append(value)
	
	return MeshData.new(color, mesh_name, shapes)

func set_body_data(body_data:BodyData):
	set_mesh_data(body_data.body_mesh, "Body","Body")
	set_mesh_data(body_data.body_mesh, "Body","Face")
	set_mesh_data(body_data.eye_mesh, "Eyes","Face")
	set_mesh_data(body_data.lashes_mesh, "Eyelashes","Face")
	set_mesh_data(body_data.hair_mesh, "Hair", "Hair")
	set_mesh_data(body_data.brow_mesh, "Brows")
	set_mesh_data(body_data.beard_mesh, "Beard")

func set_equipment_data(eq_data:EquipmentData):
	set_mesh_data(eq_data.top_mesh, "Top")
	set_mesh_data(eq_data.bottom_mesh, "Bottom")
	set_mesh_data(eq_data.shoe_mesh, "Shoes")
	set_mesh_data(eq_data.hat_mesh, "Hat")
	set_mesh_data(eq_data.r_hand_mesh, "Right Hand")
	set_mesh_data(eq_data.l_hand_mesh, "Left Hand")

func set_mesh_data(mesh_data:MeshData, mesh_name:String, tab_name:=""):
	# TODO () ugly. also used similarly in BodyGenerator, preset_tab and Creator. Assign Hands to variables
	var mesh_instance:MeshInstance3D = parent_node.skeleton.get_node(mesh_name) if !MobConstants.hand_names.has(mesh_name) else parent_node.skeleton.get_node(mesh_name).get_child(0).get_child(0)
	var material_nr = 1 if mesh_name == "Eyes" else 0 # TODO () use as input?
	
	if mesh_name == "Brows" && mesh_data.mesh_name == "empty":
		pass
	
	# set tab name if missing TODO why not just give it as arg?
	if !tab_name:
		var info_id
		for tab_name_ in parent_node.menu_data.keys(): 
			info_id = parent_node.menu_data[tab_name_].keys().find(mesh_name)
			if info_id != -1:
				tab_name = tab_name_
				break
		if !tab_name:
			print("Coudnt find tab for ",mesh_name)
			return
	
	# mesh
	if mesh_data.mesh_name:
		if parent_node.menu_data[tab_name][mesh_name][0]: # check if picker in tab
			parent_node.update_mesh_picker(mesh_data.mesh_name, tab_name, mesh_name, mesh_name)
		else:
			MobUtils.set_mesh(mesh_data.mesh_name,parent_node.skeleton.get_node(mesh_name),"")
		# TODO add else. when there is no picker change it anyway
	
	# color
	if mesh_data.mesh_color != Color(0,0,0):
		if parent_node.menu_data[tab_name][mesh_name][1]: # check if picker in tab
			parent_node.update_mesh_picker(mesh_data.mesh_color, tab_name, mesh_name, mesh_name + "Color")
	
	# shape keys
	if mesh_data.mesh_shape != []:
		var shape_names = range(0, mesh_instance.mesh.get_blend_shape_count()).map(
			func (i): return mesh_instance.mesh.get_blend_shape_name(i))
		if mesh_data.mesh_shape.size() != shape_names.size():
			print("Cant apply mesh shapes to mesh ",mesh_data.mesh_name," with size: " + str(mesh_data.mesh_shape.size()) +" to mesh with shape size: "+ str(shape_names.size()))
			return
		
		for i in mesh_data.mesh_shape.size():
			var value = mesh_data.mesh_shape[i]
			var shape_name = shape_names[i]
			if parent_node.menu_data[tab_name][mesh_name][2].has(shape_name): # check if picker in tab
				parent_node.update_mesh_picker(value, tab_name, mesh_name, shape_name)

# Other Pickers
func _on_edit_gender_value_changed(gender): # -1 - male, 1 - female
	# adjust gendered shape keys
	for shape_name:String in BodyGenerator.gender_shape_normals.keys():
		# get new gendered value
		var id = [0,1].pick_random() if gender == 0 else (gender+1)/2
		var new_value = BodyGenerator.gender_shape_normals[shape_name][id]
		
		# find mesh and tab names
		var tab_name:String
		var mesh_name:String
		for _tab_name in parent_node.menu_data.keys():
			for _mesh_name in parent_node.menu_data[_tab_name].keys():
				if parent_node.menu_data[_tab_name][_mesh_name][2].has(shape_name):
					tab_name = _tab_name
					mesh_name = _mesh_name
					break
			if tab_name:
				break
		if !mesh_name:
			continue
		
		# update shape key picker
		parent_node.update_mesh_picker(new_value,tab_name,mesh_name,shape_name)
	
	# mesh (lashes and beard)
	for mesh_name:String in MobConstants.gendered_mesh_names:
		# prepare variables
		var id = (gender+1)/2 if gender else [0,1].pick_random()
		var mesh_instance = parent_node.skeleton.get_node(mesh_name)
		var path = BodyGenerator.body_mesh_info[mesh_name].mesh_folder
		
		# get gendered list
		var file_name = "empty"
		if !MobConstants.half_empty_names.has(mesh_name) || randf() > .5: # 50% to have beard
			file_name = BodyGenerator.get_filtered_mesh_names(path, mesh_name, gender).pick_random()
		MobUtils.set_mesh(file_name,mesh_instance,path)

func _on_random_name_pressed():
	var new_name = name_list.pick_random()
	$ScrollContainer/VBoxContainer/NamePicker.text = new_name
	_on_name_picker_text_changed(new_name)

func _on_name_picker_text_changed(new_text: String):
	mob_name = new_text
	UiUtils.disable_edit([$"../../Start Game"],!mob_name)
	
	if presets.find(func (preset): preset.name == new_text) != -1:
		UiUtils.button_show_warning(save_button_node,override_warning)
	else:
		UiUtils.button_hide_warning(save_button_node)

func race_changed(race:String):
	var race_id:int = MobConstants.MobRaces[race]
	var type:int = MobConstants.MobTypes[mob_type_picker.selected_value]
	var gender = mob_gender_picker.value
	$RaceController.race_changed(race_id,type,gender,parent_node.skeleton)

# New randomizers.
func _on_random_body_pressed():
	var gender = mob_gender_picker.value
	set_body_data(BodyGenerator.get_random_body(parent_node.skeleton,gender))

func _on_random_clothes_pressed():
	var type:int = MobConstants.MobTypes[mob_type_picker.selected_value]
	var gender = mob_gender_picker.value
	set_equipment_data(BodyGenerator.get_random_equipment(parent_node.skeleton,gender,type))
