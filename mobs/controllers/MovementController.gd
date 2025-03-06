extends Node

var direction := Vector3()
@onready var parent:Player = $"../../Mob"

func handle_movement(delta:float, velocity:Vector3) -> Vector3:
	var camera_rot:Basis = $"../CameraController".global_transform.basis
	
	if parent.current_state != parent.MobState.Action:
		update_direction(camera_rot)
	velocity = update_velocity(delta,velocity)
	if parent.current_state != parent.MobState.Action:
		update_animation(velocity)
	
	# rotate player model to camera when moving
	$"../CameraController".rotate_player_body(direction, parent)
	
	return velocity

func update_direction(camera_rot: Basis):
	direction = Vector3.ZERO
	if Input.is_action_pressed("Up") :
		direction -= camera_rot.z  # Forward direction
	if Input.is_action_pressed("Down") :
		direction += camera_rot.z  # Backward direction
	if Input.is_action_pressed("Left"):
		direction -= camera_rot.x  # Left direction
	if Input.is_action_pressed("Right"):
		direction += camera_rot.x  # Right direction
	
	# Normalize the move direction to maintain consistent movement speed in all directions
	if direction.length_squared() > 0:
		direction = direction.normalized()

func update_velocity(delta:float, velocity:Vector3) -> Vector3:
	if !parent.is_on_floor():
		velocity.y -= parent.gravity * delta
	velocity.x = direction.x * parent.speed
	velocity.z = direction.z * parent.speed
	
	return velocity

func update_animation(velocity:Vector3):
	if parent.current_state != parent.MobState.Action:
		if !velocity || velocity.y < 0 || !parent.is_on_floor():
			parent.current_state = parent.MobState.Idle
			parent.body_states.travel("Idle")
			var idle_anim = "Fall" if velocity.y < 0 || !parent.is_on_floor() else "Idle"
			parent.idle_states.travel(idle_anim)
		else:
			parent.current_state = parent.MobState.Movement
			parent.body_states.travel("Movement")
			parent.move_states.travel("Run" if Input.is_action_pressed("Run") else "Walk")
