extends TabBar

const override_warning := "Overriding preset with the same name"

var parent_node:Control
var save_button_node:Button

var preset_picker:HBoxContainer
var mob_type_picker:HBoxContainer
var mob_race_picker:HBoxContainer
var mob_gender_picker:HSlider
var mob_name_picker:LineEdit

var presets := {} # TODO () make into file and read from it

func _ready():
	parent_node = $"../../"
	save_button_node = $"ScrollContainer/VBoxContainer/Save Preset"
	mob_gender_picker = $ScrollContainer/VBoxContainer/GenderContainer/EditGender
	mob_name_picker = $ScrollContainer/VBoxContainer/NamePicker
	
	# setup preset picker
	presets = {} # TODO () read saved presets from when connected to game
	preset_picker = $ScrollContainer/VBoxContainer/Preset
	preset_picker.init(presets.keys(), "Preset") # setup slider with loaded presets
	preset_picker.variable_changed.connect(_on_preset_changed)
	
	# setup type picker TODO () remove when connected to game
	mob_type_picker = $ScrollContainer/VBoxContainer/MobType
	mob_type_picker.init(MobConstants.MobTypes.keys(), "Mob Type")
	mob_type_picker.variable_changed.connect(_on_type_changed)
	
	# setup race picker TODO () remove when connected to game
	mob_race_picker = $ScrollContainer/VBoxContainer/Race
	mob_race_picker.init(MobConstants.MobRaces.keys(), "Race")
	mob_race_picker.variable_changed.connect(_on_race_changed)

func _on_save_preset_pressed():
	# TODO save body_data into saved_presets.json file
	var old_data:MobData = Utils.duplicate_node(parent_node.mob_data)
	var new_data:MobData = MobData.new(
		old_data.race,old_data.type,old_data.mob_name,old_data.gender,
		old_data.body_data,old_data.equipment_data
	)
	
	#Utils.duplicate_node(parent_node.mob_data)
	presets[new_data.mob_name] = new_data # TODO () in game, you can use real methods
	#print("saving ",new_data.mob_name)
	#print("races ",presets.values().map(func (mb): return mb.race))
	
	# update slider
	if !preset_picker.picker:
		preset_picker.init(presets.keys(), "Preset")
	else:
		preset_picker.picker.max_value += 1
		preset_picker.values.append(parent_node.mob_data.mob_name)
	
	if preset_picker.picker:
		preset_picker.picker.set_value(preset_picker.picker.max_value)
	
	UiUtils.button_show_warning(save_button_node,override_warning)

func mesh_to_mesh_data(mesh:MeshInstance3D) -> MeshData:
	var color := MobUtils.get_mesh_color(mesh)
	var mesh_name := mesh.mesh.resource_path.split("/")[-1].trim_suffix(".tres") if mesh.visible else "empty"
	var shapes := []
	for i in mesh.get_blend_shape_count():
		var value = int(mesh.get_blend_shape_value(i)*10) / 10.0 # TODO but what if its 2 spaces after comma?
		shapes.append(value)
	
	return MeshData.new(color, mesh_name, shapes)

# Other Pickers
func _on_gender_changed(gender:int): # 0 - male, 2 - female
	if parent_node.mob_data.gender == gender:
		return
	
	parent_node.mob_data.gender = gender
	if parent_node.mob_data.body_data.brow_mesh.mesh_name: # TODO shouldnt be here
		print("brow2 ",parent_node.mob_data.body_data.brow_mesh.mesh_name)
	
	if gender != MobConstants.Gender.NonBin:
		parent_node.mob_data = BodyGenerator.get_random_mob_data(parent_node.skeleton, parent_node.mob_data.race, parent_node.mob_data.type, parent_node.mob_data.gender, parent_node.mob_data.mob_name, parent_node.mob_data)
	BodyGenerator.set_mob_data_to_mob(parent_node.mob_data,parent_node.mob)
	parent_node.update_all_pickers()

func _on_random_name_pressed():
	var new_name = MobConstants.mob_names[parent_node.mob_data.gender].pick_random()
	$ScrollContainer/VBoxContainer/NamePicker.text = new_name
	_on_mob_name_changed(new_name)

# TODO name changes then save preset doesnt work very well...
func _on_mob_name_changed(new_text: String):
	if parent_node.mob_data.mob_name == new_text:
		return
	parent_node.mob_data.mob_name = new_text
	
	UiUtils.disable_edit($"../../Start Game",!new_text)
	UiUtils.disable_edit($"ScrollContainer/VBoxContainer/Save Preset",!new_text)
	
	if presets.has(new_text):
		print("showing warning")
		UiUtils.button_show_warning(save_button_node,override_warning)
	else:
		print("hiding warning")
		UiUtils.button_hide_warning(save_button_node)

func _on_race_changed(race_v:String):
	if parent_node.mob_data.race == MobConstants.MobRaces[race_v]:
		return
	
	# TODO otherwise, it changes race of the last saved preset for some reason. GRRRR
	#print("preset races1 ",presets.values().map(func (mb): return mb.race))
	var last_races:Array = presets.values().map(func (mb:MobData): return mb.race)
		
	parent_node.mob_data.race = MobConstants.MobRaces[race_v]
	
	if last_races: 
		range(presets.size()).map(func (i): presets.values()[i].race = last_races[i])
	#print("preset races2 ",presets.values().map(func (mb): return mb.race))
	
	parent_node.mob_data = BodyGenerator.get_random_mob_data(parent_node.skeleton, parent_node.mob_data.race, 
		parent_node.mob_data.type, parent_node.mob_data.gender, parent_node.mob_data.mob_name)
	
	BodyGenerator.set_mob_data_to_mob(parent_node.mob_data,parent_node.mob)
	parent_node.update_all_pickers()

func _on_type_changed(type_v:String):
	if parent_node.mob_data.type == MobConstants.MobTypes[type_v]:
		return
	parent_node.mob_data.type = MobConstants.MobTypes[type_v]
	_on_random_clothes_pressed()

func _on_preset_changed(mob_name:String):
	var mob_data:MobData = presets[mob_name]
	parent_node.mob_data = mob_data
	BodyGenerator.set_mob_data_to_mob(mob_data,parent_node.mob)
	parent_node.update_all_pickers()

# New randomizers.
func _on_random_body_pressed():
	parent_node.mob_data.body_data = BodyGenerator.get_random_body(parent_node.skeleton,parent_node.mob_data.gender,parent_node.mob_data.type,parent_node.mob_data.race)
	#parent_node.mob_data = BodyGenerator.adjust_mob_data_to_race(parent_node.mob_data, parent_node.mob_data.race)
	BodyGenerator.set_body_data(parent_node.mob_data.body_data,parent_node.mob)
	parent_node.update_all_pickers()

func _on_random_clothes_pressed():
	parent_node.mob_data.equipment_data = BodyGenerator.get_random_equipment(parent_node.skeleton,parent_node.mob_data.gender,parent_node.mob_data.type,parent_node.mob_data.race)
	BodyGenerator.set_equipment_data(parent_node.mob_data.equipment_data,parent_node.mob)
	parent_node.update_all_pickers()
