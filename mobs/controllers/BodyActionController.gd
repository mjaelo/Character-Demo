extends Node
# TODO rename to body action?
@onready var parent_mob:Mob = $"../../"
@onready var parent_controller:ActionHandler = $"../"

# trigger action on a frame
var frame_trigger:= {"Jump": {"treshold": .5, "prev": 0, "action": func (): parent_mob.velocity.y += parent_mob.jump_impulse}}

func check_frame():
	var action_name := parent_controller.action_state_machine.get_current_node()
	var play_pos := parent_controller.action_state_machine.get_current_play_position()
	if frame_trigger.has(action_name):
		var info = frame_trigger[action_name]
		if !info.treshold || (info.prev <= info.treshold && info.treshold < play_pos):
			info.action.call()
		info.prev = play_pos

# EXTERNAL SIGNALS
func on_action_pressed(action_name: String):
	print(action_name," Action pressed")
	# check if can perform action
	if !parent_mob.is_on_floor() || (action_name == "Roll" && !parent_mob.velocity):
		return
	
	# perform action
	parent_controller.current_controller = parent_controller.MobControllers.Action
	parent_controller.body_state_machine.start("Action")
	parent_controller.action_state_machine.travel(action_name)
	if action_name == "Roll":
		parent_mob.current_speed = parent_mob.normal_speed * parent_controller.press_speed_modifiers["Roll"]
		print("Roll speed up")

func on_animation_finished(anim_name: String):
	parent_mob.velocity.x = 0
	parent_mob.velocity.z = 0
	if anim_name.contains("Jump"):
		parent_controller.idle_state_machine.travel("Fall") # decide if fall. (shouldnt be needed, right?)
