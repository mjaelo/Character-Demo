extends HBoxContainer
class_name SliderPickerComponent
# UI Scene that displays an HSlider to pick a value from a given list, plus a randomize button.

var selected_value = null
var values: Array = []
var picker: HSlider

@export var disabled: bool = false:
	set(value):
		disabled = value
		UIUtils.disable_edit(self, value)

signal variable_changed(new_value)

func init(_values: Array, header: String = "") -> void:
	values = _values
	$VBoxContainer/Labels/Name.text = header

	if values.size() < 2:
		if values.size() == 1:
			_on_picker_value_changed(0)
		disabled = true
		return
	disabled = false

	picker = HSlider.new()
	picker.max_value = values.size() - 1
	picker.value_changed.connect(_on_picker_value_changed)
	$VBoxContainer.add_child(picker)
	_on_picker_value_changed(0)

func set_value(value) -> void:
	if disabled:
		return
	var val_id := -1
	for i in values.size():
		if values[i] == value:
			val_id = i
			break
	if val_id != -1:
		picker.value = val_id
	else:
		if !str(value) == "empty":
			print(name + ": " + str(value) + " not found in " + str(values))

func _on_random_button_pressed() -> void:
	if !picker:
		print("Missing picker on ", name)
		return
	if !values:
		disabled = true
		return
	set_value(values.pick_random())

func _on_picker_value_changed(new_index) -> void:
	var new_value = values[int(new_index)]
	if selected_value != new_value:
		selected_value = new_value
		$VBoxContainer/Labels/Value.text = str(selected_value)
		emit_signal("variable_changed", new_value)
