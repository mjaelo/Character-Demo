extends Node

# Edit rights
func disable_edit(node:Control, disabled:bool):
	if node.has_method("set_disabled") || node is BaseButton:
		node.disabled = disabled
		change_label_visibility(node,disabled)
	elif node.has_method("set_editable"):
		node.editable = !disabled
	elif node is Label:
		change_label_visibility(node,disabled)
	
	for child:Control in node.get_children():
		disable_edit(child,disabled)

func change_label_visibility(label:CanvasItem, disabled:bool)-> CanvasItem:
	if !label:
		return
	if disabled:
		label.modulate.a=.2
	else:
		label.modulate.a=1
	return label

func button_show_warning(button:Button, tooltip_text := "Warning"):
	button.icon = FileUtils.load_image_from_file(UIConstants.WARNING_ICON_PATH)
	button.tooltip_text = tooltip_text

func button_hide_warning(button:Button):
	button.icon = null
	button.tooltip_text = ""

func get_colors_from_color_range(cr: ColorRangeInfo)->Array[Color]:
	var color_values: Array[Color] = []
	var colors := 10
	for i in colors:
		var weight := float(i) / float(colors - 1)
		var h :float= lerp(cr.hue.x, cr.hue.y, weight)
		var s :float= lerp(cr.saturation.x, cr.saturation.y, weight)
		var v :float= lerp(cr.brightness.x, cr.brightness.y, weight)
		color_values.append(Color.from_hsv(h, s, v))
	return color_values
	
func get_color_range_from_color(color:Color)->ColorRangeInfo:
	return ColorRangeInfo.new(Vector2(color.h,color.h),Vector2(color.s,color.s),Vector2(color.v,color.v),Vector2(color.a,color.a))