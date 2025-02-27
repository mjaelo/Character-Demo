extends Mob
class_name Player

# PROCESSES
func _unhandled_input(_event:InputEvent):
	for action:String in InputMap.get_actions():
		if Input.is_action_just_pressed(action):
			#if race == MobConstants.MobRaces.Statue:
				#anim_tree.active = true
			if body_states.get_current_node() != "Action" && is_on_floor():
				handle_action_press(action)
		elif Input.is_action_just_released(action) && is_on_floor():
			handle_action_release(action)

# ACTION HANDLERS
func handle_action_press(action:String):
	if race == MobConstants.MobRaces.Statue:
		anim_tree.active = true
	
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
