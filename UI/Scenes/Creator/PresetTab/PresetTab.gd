extends TabBar
class_name PresetTab

var override_warning: String = UIConstants.OVERRIDE_WARNING
var parent:Creator

@onready var start_game_button := $"../../CreatorCameraManager/Start Game" # TODO move outside CreatorCameraManager
@onready var camera_manager := $"../../CreatorCameraManager"
@onready var save_preset_button := $"ScrollContainer/VBoxContainer/Preset Handler/Save Preset"
@onready var delete_preset_button := $"ScrollContainer/VBoxContainer/Preset Handler/Delete Preset"

@onready var preset_picker :SliderPickerComponent= $ScrollContainer/VBoxContainer/Preset
@onready var mob_type_picker :SliderPickerComponent= $ScrollContainer/VBoxContainer/MobType
@onready var mob_race_picker :SliderPickerComponent= $ScrollContainer/VBoxContainer/Race
@onready var mob_gender_picker:= $ScrollContainer/VBoxContainer/GenderContainer/EditGender
@onready var mob_name_picker := $ScrollContainer/VBoxContainer/NamePicker

var def_name: String = UIConstants.DEFAULT_PRESET_NAME
var presets := {def_name: {}}

func initialize(_parent:Creator):
	parent = _parent
	
	# load presets from file
	var saved_presets = FileUtils.serialize_and_load("preset.json","res://UI/Scenes/Creator/")
	for key in saved_presets.keys():
		presets[key] = saved_presets[key]
	
	# setup preset, type and race pickers
	preset_picker.init(presets.keys(), "Preset")
	preset_picker.variable_changed.connect(_on_preset_changed)
	mob_type_picker.init(MobConstants.MobTypes.keys(), "Mob Type")
	mob_type_picker.variable_changed.connect(_on_type_changed)
	mob_race_picker.init(MobConstants.MobRaces.keys(), "Race")
	mob_race_picker.variable_changed.connect(_on_race_changed)

# Preset UI elements Callbacks
func _on_save_preset_pressed():
	var old_data:MobData = parent.mob_data
	var new_data:MobData = MobData.new(
		old_data.race,old_data.type,old_data.mob_name,old_data.gender,
		old_data.body_data,old_data.equipment_data
	)
	
	presets[new_data.mob_name] = new_data
	
	# update slider
	if !preset_picker.picker:
		preset_picker.init(presets.keys(), "Preset")
	else:
		preset_picker.picker.max_value += 1
		preset_picker.values.append(parent.mob_data.mob_name)
	
	if preset_picker.picker:
		preset_picker.picker.set_value(preset_picker.picker.max_value)
	
	UIUtils.button_show_warning(save_preset_button,override_warning)

func _on_delete_preset_pressed() -> void:
	var current_name = parent.mob_data.mob_name
	presets.erase(current_name)
	preset_picker.picker.max_value -= 1
	preset_picker.values.erase(current_name)
	preset_picker.set_value(def_name)
	_on_preset_changed(def_name)

func _on_preset_changed(mob_name:String):
	var is_new_character := mob_name == def_name
	UIUtils.disable_edit(delete_preset_button, is_new_character)
	if !is_new_character:
		var mob_data:MobData = presets[mob_name]
		parent.mob_data = mob_data
		parent.tab_builder.mob_data = mob_data
		MobSetter.set_mob_data_to_mob(mob_data,parent.player)
		parent.update_all_pickers()
	else:
		parent.randomize_all()

# Gender, Name, Type and Race UI elements Callbacks
func _on_gender_changed(gender:int): # 0 - male, 2 - female
	if parent.mob_data.gender == gender:
		return
	
	parent.mob_data.gender = gender
	
	if gender != MobConstants.Gender.NonBin:
		var norms: Array[NormData] = []
		norms.append_array(MobConstants.gender_norms[gender])
		parent.mob_data.body_data = MobAdjuster.adjust_body_data(parent.skeleton, norms, parent.mob_data.body_data)
		parent.mob_data.equipment_data = MobAdjuster.adjust_equipment_data(parent.skeleton, norms, parent.mob_data.equipment_data)
	MobSetter.set_mob_data_to_mob(parent.mob_data, parent.player)
	parent.update_all_pickers()

func _on_random_name_pressed():
	var new_name = MobConstants.mob_names[parent.mob_data.gender].pick_random()
	mob_name_picker.text = new_name
	_on_mob_name_changed(new_name)

func _on_mob_name_changed(new_text: String):
	if parent.mob_data.mob_name == new_text:
		return
	parent.mob_data.mob_name = new_text
	
	UIUtils.disable_edit(start_game_button,!new_text)
	UIUtils.disable_edit(save_preset_button,!new_text)
	
	if presets.has(new_text):
		UIUtils.button_show_warning(save_preset_button,override_warning)
	else:
		UIUtils.button_hide_warning(save_preset_button)

func _on_race_changed(race_v:String):
	camera_manager.set_camera_height_by_race(MobConstants.MobRaces[race_v])
	if parent.mob_data.race == MobConstants.MobRaces[race_v]:
		return
	
	# otherwise, it changes race of the last saved preset for some reason. GRRRR
	var mob_presets := presets.values().filter(func(v): return v is MobData)
	var last_races: Array = mob_presets.map(func(mb: MobData): return mb.race)
	parent.mob_data.race = MobConstants.MobRaces[race_v]
	if last_races:
		var idx := 0
		for key in presets.keys():
			if presets[key] is MobData:
				presets[key].race = last_races[idx]
				idx += 1
	
	# adjust current mob data with new race norms
	var norms: Array[NormData] = []
	norms.append_array(MobConstants.race_norms[parent.mob_data.race])
	parent.mob_data.body_data = MobAdjuster.adjust_body_data(parent.skeleton, norms, parent.mob_data.body_data)
	parent.mob_data.equipment_data = MobAdjuster.adjust_equipment_data(parent.skeleton, norms, parent.mob_data.equipment_data)
	MobSetter.set_mob_data_to_mob(parent.mob_data, parent.player)
	parent.set_mob_data_to_pickers(parent.mob_data)

func _on_type_changed(type_v:String):
	if parent.mob_data.type == MobConstants.MobTypes[type_v]:
		return
	parent.mob_data.type = MobConstants.MobTypes[type_v]
	_on_random_clothes_pressed()

# General Randomizers
func _on_random_body_pressed():
	var norms_body := MobGetter._get_rtg_norms(parent.mob_data.race, parent.mob_data.type, parent.mob_data.gender)
	parent.mob_data.body_data = MobGetter.get_random_body_data(parent.skeleton, norms_body)
	#parent.mob_data = MobAdjuster.adjust_mob_data_to_race(parent.mob_data, parent.mob_data.race)
	MobSetter.set_body_data(parent.mob_data.body_data, parent.player)
	parent.set_mob_data_to_pickers(parent.mob_data)

func _on_random_clothes_pressed():
	var norms_eq := MobGetter._get_rtg_norms(parent.mob_data.race, parent.mob_data.type, parent.mob_data.gender)
	parent.mob_data.equipment_data = MobGetter.get_random_equipment_data(parent.skeleton, norms_eq)
	MobSetter.set_equipment_data(parent.mob_data.equipment_data, parent.player)
	parent.set_mob_data_to_pickers(parent.mob_data)

func _on_randomize_all_pressed() -> void:
	parent.randomize_all()

# Utils
func set_mob_data_to_preset_pickers(mob_data:MobData):
	mob_name_picker.text = mob_data.mob_name
	mob_type_picker.picker.value = mob_data.type
	mob_race_picker.picker.value = mob_data.race
	mob_gender_picker.value = mob_data.gender
