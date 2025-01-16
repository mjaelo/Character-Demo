extends HBoxContainer

var selected_value = null : set = set_value
var values := range(0,100)
@export var picker: Control
var disabled:bool = false: 
	set(value):
		disabled = value
		UiUtils.disable_edit(get_children(),value)

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
func set_value(value):
	if selected_value != value:
		selected_value = value
		$VBoxContainer/Labels/Value.text = str(selected_value)
		emit_signal("variable_changed", value) 

func _on_random_button_pressed():
	var random_value
	if !picker:
		print("Missing picker on ",name)
		return
	if !values:
		disabled = true
		return
		#var r = range(0,100)
		#values = r if picker is HSlider else [r,r,r]
	if picker is HSlider:
		random_value = randi() % values.size()
		picker.value = random_value
	elif picker is ColorPickerButton:
		random_value = Color.from_hsv(
			values[0].pick_random(),
			values[1].pick_random(),
			values[2].pick_random()
		)
		picker.color = random_value
	_on_picker_value_changed(random_value)

func _on_picker_value_changed(new_value):
	selected_value = new_value if new_value is Color else values[new_value]
