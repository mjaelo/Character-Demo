extends TabBar

var override_warning: String = UIConstants.OVERRIDE_WARNING

@onready var parent := $"../../"

@onready var start_game_button := $"../../RightCreator/Start Game"
@onready var save_preset_button := $"ScrollContainer/VBoxContainer/Preset Handler/Save Preset"
@onready var delete_preset_button := $"ScrollContainer/VBoxContainer/Preset Handler/Delete Preset"

@onready var preset_picker :SliderPickerComponent= $ScrollContainer/VBoxContainer/Preset
@onready var mob_type_picker :SliderPickerComponent= $ScrollContainer/VBoxContainer/MobType
@onready var mob_race_picker :SliderPickerComponent= $ScrollContainer/VBoxContainer/Race
@onready var mob_gender_picker:= $ScrollContainer/VBoxContainer/GenderContainer/EditGender
@onready var mob_name_picker := $ScrollContainer/VBoxContainer/NamePicker

var def_name: String = UIConstants.DEFAULT_PRESET_NAME
var presets := {def_name: {}}

func _ready():
	# setup preset picker
	var saved_presets = FileUtils.serialize_and_load("preset.json","res://UI/Scenes/Creator/")
	for key in saved_presets.keys():
		presets[key] = saved_presets[key]
	
	preset_picker.init(presets.keys(), "Preset") # setup slider with loaded presets
	preset_picker.variable_changed.connect(_on_preset_changed)
	
	# setup type picker TODO () remove when connected to game
	mob_type_picker.init(MobConstants.MobTypes.keys(), "Mob Type")
	mob_type_picker.variable_changed.connect(_on_type_changed)
	
	# setup race picker TODO () remove when connected to game
	mob_race_picker.init(MobConstants.MobRaces.keys(), "Race")
	mob_race_picker.variable_changed.connect(_on_race_changed)

# PRESET
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
		MobGenerator.set_mob_data_to_mob(mob_data,parent.mob)
		parent.update_all_pickers()
	else:
		parent.randomize_all()


# Other Pickers
func _on_gender_changed(gender:int): # 0 - male, 2 - female
	if parent.mob_data.gender == gender:
		return
	
	parent.mob_data.gender = gender
	
	if gender != MobConstants.Gender.NonBin:
		parent.mob_data = MobGenerator.get_random_mob_data(parent.skeleton, parent.mob_data.race, parent.mob_data.type, parent.mob_data.gender, parent.mob_data.mob_name, parent.mob_data)
	MobGenerator.set_mob_data_to_mob(parent.mob_data,parent.mob)
	parent.update_all_pickers()

func _on_random_name_pressed():
	var new_name = MobConstants.mob_names[parent.mob_data.gender].pick_random()
	mob_name_picker.text = new_name
	_on_mob_name_changed(new_name)

# TODO name changes then save preset doesnt work very well...
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
	parent.get_node("RightCreator").set_camera_height_by_race(MobConstants.MobRaces[race_v])
	if parent.mob_data.race == MobConstants.MobRaces[race_v]:
		return
	
	# otherwise, it changes race of the last saved preset for some reason. GRRRR
	var last_races:Array = presets.values().map(func (mb:MobData): return mb.race)
	parent.mob_data.race = MobConstants.MobRaces[race_v]
	if last_races: 
		range(presets.size()).map(func (i): presets.values()[i].race = last_races[i])
	
	# adjust current mob data
	parent.mob_data = MobGenerator.get_random_mob_data(parent.skeleton, parent.mob_data.race, 
		parent.mob_data.type, parent.mob_data.gender, parent.mob_data.mob_name)
	MobGenerator.set_mob_data_to_mob(parent.mob_data,parent.mob)
	parent.update_all_pickers()

func _on_type_changed(type_v:String):
	if parent.mob_data.type == MobConstants.MobTypes[type_v]:
		return
	parent.mob_data.type = MobConstants.MobTypes[type_v]
	_on_random_clothes_pressed()

# New randomizers.
func _on_random_body_pressed():
	parent.mob_data.body_data = MobGenerator.get_random_body(parent.skeleton,parent.mob_data.gender,parent.mob_data.type,parent.mob_data.race)
	#parent.mob_data = MobGenerator.adjust_mob_data_to_race(parent.mob_data, parent.mob_data.race)
	MobGenerator.set_body_data(parent.mob_data.body_data,parent.mob)
	parent.update_all_pickers()

func _on_random_clothes_pressed():
	parent.mob_data.equipment_data = MobGenerator.get_random_equipment(parent.skeleton,parent.mob_data.gender,parent.mob_data.type,parent.mob_data.race)
	MobGenerator.set_equipment_data(parent.mob_data.equipment_data,parent.mob)
	parent.update_all_pickers()

func _on_randomize_all_pressed() -> void:
	parent.randomize_all()
