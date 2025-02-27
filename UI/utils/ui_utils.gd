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
	button.icon = load("res://assets/UI/Warning.png") # TODO use cached resource
	button.tooltip_text = tooltip_text

func button_hide_warning(button:Button):
	button.icon = null
	button.tooltip_text = ""
