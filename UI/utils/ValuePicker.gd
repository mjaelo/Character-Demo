extends HBoxContainer

var selected_value = null
var values := range(0,100)
@export var picker: Control
@export var disabled:bool = false: 
	set(value):
		disabled = value
		UiUtils.disable_edit(self,value)

signal variable_changed(new_value)

func init(_values:Array, value_name:="", type:="slider"):
	values = _values
	$VBoxContainer/Labels/Name.text = value_name
	
	if values.size()<2:
		if values.size() == 1:
			_on_picker_value_changed(0)
		disabled = true
		return
	disabled = false
	
	if type == "slider":
		picker = HSlider.new()
		picker.max_value = values.size()-1
		picker.value_changed.connect(_on_picker_value_changed)
		_on_picker_value_changed(0)
	elif type == "color":
		picker = ColorPickerButton.new()
		picker.custom_minimum_size.y=20
		picker.color_changed.connect(_on_picker_value_changed)
	$VBoxContainer.add_child(picker)

# Functionality
func _on_random_button_pressed():
	if !picker:
		print("Missing picker on ",name)
		return
	if !values:
		disabled = true
		return
	
	var random_value
	if picker is HSlider:
		random_value = values.pick_random()
	elif picker is ColorPickerButton:
		random_value = Color.from_hsv(
			values[0].pick_random(),
			values[1].pick_random(),
			values[2].pick_random()
		)
	set_value(random_value)

func set_value(value):
	if disabled:
		return
	if picker is ColorPickerButton:
		picker.color = value
		_on_picker_value_changed(value)
	else:
		# getting value id in list
		var val_id:= -1 #= values.find(value,0) # i hate that that doesnt work. grrr.
		for val in values.size():
			if values[val] == value:
				val_id = val
				break
		
		# update picker value
		if val_id != -1:
			picker.value = val_id
		else:
			if !str(value) == "empty":
				print(picker.name + ": " + str(value) + " not found in " + str(values))

func _on_picker_value_changed(new_value):
	new_value = new_value if new_value is Color else values[new_value]
	if selected_value != new_value:
		selected_value = new_value
		$VBoxContainer/Labels/Value.text = str(selected_value)
		emit_signal("variable_changed", new_value)
