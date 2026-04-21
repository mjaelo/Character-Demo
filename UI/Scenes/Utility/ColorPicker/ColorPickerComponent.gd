extends HBoxContainer
class_name ColorPickerComponent
# UI Scene that displays a ColorPickerButton and an array of color ranges to pick a color

var selected_value: Color = Color.WHITE
var values: Array = []  # [hue_range, sat_range, val_range]
var picker: ColorPickerButton

@export var disabled: bool = false:
	set(value):
		disabled = value
		UIUtils.disable_edit(self, value)

signal variable_changed(new_value)

func init(_values: Array[Color], header: String = "") -> void:
	values = _values
	$VBoxContainer/Labels/Name.text = header

	if values.size() < 1:
		disabled = true
		return
	disabled = false

	picker = ColorPickerButton.new()
	picker.custom_minimum_size.y = 20
	picker.color_changed.connect(_on_picker_value_changed)
	$VBoxContainer.add_child(picker)

func set_value(value: Color) -> void:
	if disabled:
		return
	picker.color = value
	_on_picker_value_changed(value)

func _on_random_button_pressed() -> void:
	if !picker:
		print("Missing picker on ", name)
		return
	if values.size() < 3:
		disabled = true
		return
	var random_color = Color.from_hsv(
		values[0].pick_random(),
		values[1].pick_random(),
		values[2].pick_random()
	)
	set_value(random_color)

func _on_picker_value_changed(new_value: Color) -> void:
	if selected_value != new_value:
		selected_value = new_value
		$VBoxContainer/Labels/Value.text = str(selected_value)
		emit_signal("variable_changed", new_value)
