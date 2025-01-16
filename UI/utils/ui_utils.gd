extends Node

# Edit rights
func disable_edit(children:Array, disabled:bool):
	for child:Control in children:
		if child.has_method("set_disabled") || child is BaseButton:
			child.disabled = disabled
			change_label_visibility(child,disabled)
		elif child.has_method("set_editable"):
			child.editable = !disabled
		elif child is Label:
			change_label_visibility(child,disabled)
		
		disable_edit(child.get_children(),disabled)

func change_label_visibility(label:CanvasItem, disabled:bool)-> CanvasItem:
	if !label:
		return
	if disabled:
		label.modulate.a=.2
	else:
		label.modulate.a=1
	return label

func button_show_warning(button:Button,tooltip_text:="Warning"):
	button.icon = load("res://UI/assets/Warning.png")
	button.tooltip_text = tooltip_text

func button_hide_warning(button:Button):
	button.icon = null
	button.tooltip_text = ""
