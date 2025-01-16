extends "../Mob.gd"
class_name Player


# TODO
	# skip?
		# allow armanims to move legs when not moving
		# actions are often not called
	# difficult
		# tpose often on arm action - change blend shape when cur anim len > 0?
		#  collisionshape should adjust with body position
	# add anims:
		# when attacking with empty hand, raise hands instead of drawing sword - anim needed
		# if no shield, block with sword - anim needed
		# drawing shield uses wrong hand - anim needed
	# animations
		# make block not persist after letting it go
		# make it possible to move when rolling and jumping
		# slow movement when blocking
		# set blend to 0 when not moving

# PROCESSES
func _physics_process(delta):
	# trigger action on a frame
	if body_states.get_current_node() == "Action":
		check_frame(action_controller.frame_trigger, action_states.get_current_play_position(), action_states.get_current_node())
	elif body_blend > 0:
		check_frame(combat_controller.frame_trigger, arm_states.get_current_play_position(), arm_states.get_current_node())
	
	velocity = movement_controller.handle_movement(delta, velocity)
	
	# Move
	move_and_slide()

func _unhandled_input(_event:InputEvent):
	for action:String in InputMap.get_actions():
		if Input.is_action_just_pressed(action):
			if body_states.get_current_node() != "Action" && is_on_floor():
				handle_action_press(action)
		elif Input.is_action_just_released(action) && is_on_floor():
			handle_action_release(action)

# ACTION HANDLERS
func handle_action_press(action:String):
	if hold_speed_modifiers.has(action):
		speed = normal_speed * hold_speed_modifiers[action]
	
	if MoveActions.keys().has(action):
		return # handled by _physics_process
	
	body_states.stop()
	
	# handle body actions
	if BodyActions.keys().has(action):
		action_controller._on_body_action_pressed(action)
	
	# handle arm actions (combat)
	elif ArmActions.keys().has(action):
		combat_controller._on_combat_action_pressed(action)

func handle_action_release(action:String):
	if hold_speed_modifiers.has(action):
		speed = normal_speed
	
	if ArmActions.keys().has(action):
		combat_controller._on_combat_action_released(action)
