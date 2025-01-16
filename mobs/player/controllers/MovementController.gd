extends Node

var direction := Vector3()
@onready var parent:Player = $"../../Mob"

func handle_movement(delta:float, velocity:Vector3) -> Vector3:
	var camera_rot = $"../CameraController".global_transform.basis
	
	if parent.body_states.get_current_node() != "Action":
		update_direction(camera_rot)
	velocity = updaye_velocity(delta,velocity)
	if parent.body_states.get_current_node() != "Action":
		update_animation(velocity)
	
	# rotate player model to camera when moving
	if direction != Vector3.ZERO && parent.speed > 0:
		var camera_yaw = atan2(camera_rot.z.x, camera_rot.z.z)
		parent.get_node("body").rotation.y = camera_yaw + PI # Add PI to make the player face the same direction as the camera
	
	return velocity

func update_direction(camera_rot):
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

func updaye_velocity(delta:float, velocity:Vector3) -> Vector3:
	if !parent.is_on_floor():
		velocity.y -= parent.gravity * delta
	velocity.x = direction.x * parent.speed
	velocity.z = direction.z * parent.speed
	
	return velocity

func update_animation(velocity:Vector3):
	if parent.body_states.get_current_node() != "Action":
		if !velocity || velocity.y < 0 || !parent.is_on_floor():
			parent.body_states.travel("Idle")
			var idle_anim = "Fall" if velocity.y < 0 || !parent.is_on_floor() else "Idle"
			parent.idle_states.travel(idle_anim)
		else:
			parent.body_states.travel("Movement")
			parent.move_states.travel("Run" if Input.is_action_pressed("Run") else "Walk")
