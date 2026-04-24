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
