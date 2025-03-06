extends Node

@onready var parent:Mob = $"../../"

# trigger action on a frame
var frame_trigger:= {"Jump": {"treshold": .5, "prev": 0, "action": func (): parent.velocity.y += parent.jump_impulse}}

func _on_body_action_pressed(action_name: String):
	# check if can perform action
	if action_name == "Jump" && !parent.is_on_floor():
		return
	elif action_name == "Roll" && (!parent.velocity || !parent.is_on_floor()):
		return
	
	# perform action
	parent.current_state = parent.MobState.Action
	parent.body_states.start("Action")
	parent.action_states.travel(action_name)

func _on_body_action_finished(action_name: String):
	parent.body_states.travel("Idle")
	parent.current_state = parent.MobState.Idle
	if action_name == "Jump":
		parent.idle_states.travel("Fall")
