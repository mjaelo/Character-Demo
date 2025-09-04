extends Node

@onready var parent_mob:Mob = $"../../"
@onready var parent_controller:ActionHandler = $"../"

func handle_movement(delta: float):
	handle_input(delta)
	handle_animation()

func handle_input(delta:float):
	if !parent_mob.is_on_floor():
		parent_mob.velocity.y -= parent_mob.gravity * delta

	var input_direction = Vector3.ZERO
	if Input.is_action_pressed("Up"):
		input_direction -= parent_mob.camera_controller.global_transform.basis.z
	if Input.is_action_pressed("Down"):
		input_direction += parent_mob.camera_controller.global_transform.basis.z
	if Input.is_action_pressed("Left"):
		input_direction -= parent_mob.camera_controller.global_transform.basis.x
	if Input.is_action_pressed("Right"):
		input_direction += parent_mob.camera_controller.global_transform.basis.x
	
	if input_direction.length_squared() > 0:
		input_direction = input_direction.normalized()
	
	parent_mob.velocity.x = input_direction.x * parent_mob.current_speed
	parent_mob.velocity.z = input_direction.z * parent_mob.current_speed
	parent_mob.direction = input_direction

func handle_animation():
	if can_walk():
		parent_controller.body_state_machine.travel("Movement")
		
		# stop idle event
		if parent_controller.idle_controller.performing_event:
			parent_controller.idle_controller.performing_event = false
			parent_controller.body_idle_state_machine.next()
			parent_controller.body_state_machine.start("Movement")
		
		# move or run
		if Input.is_action_pressed("Run") && parent_mob.current_speed == parent_mob.normal_speed:
			parent_controller.movement_state_machine.travel("Run")
			parent_mob.current_speed = parent_mob.normal_speed * parent_controller.hold_speed_modifiers["Run"]
		else:
			parent_controller.movement_state_machine.travel("Walk")
	elif !parent_controller.idle_controller.performing_event:
		parent_controller.body_state_machine.travel("Idle")
	
	if can_reset_speed():
		parent_mob.current_speed = parent_mob.normal_speed

func can_reset_speed()->bool:
	return !Input.is_action_pressed("Run") && !parent_controller.arm_blend && parent_controller.body_state_machine.get_current_node() != "Action" && parent_mob.current_speed != parent_mob.normal_speed

func can_walk()->bool:
	return parent_mob.direction && parent_mob.velocity && parent_mob.is_on_floor() && parent_controller.body_state_machine.get_current_node() != "Action"
