extends Mob
class_name Player

@onready var camera_controller:Node3D = $"../Controllers/CameraController"

# PROCESSES
func _unhandled_input(event:InputEvent):
	if event is InputEventMouse || Input.is_action_pressed("Switch Camera"):
		camera_controller.handle_input(event)

func handle_player_input(delta):
	# movement
	action_handler.movement_controller.handle_movement(delta)
	if velocity != Vector3.ZERO:
		rotate_player_body()
	
	# combat, action
	var combat_keys := action_handler.CombatKeys.keys()
	var action_keys := action_handler.ActionKeys.keys()
	for action:String in action_keys:
		if Input.is_action_just_pressed(action):
			action_handler.action_controller.on_action_pressed(action)
			return
		elif Input.is_action_just_released(action):
			return
	for action:String in combat_keys:
		if Input.is_action_just_pressed(action):
			action_handler.combat_controller.on_action_pressed(action)
			return
		elif Input.is_action_just_released(action):
			action_handler.combat_controller.on_action_released(action)
			return

# rotate player model to camera when moving
func rotate_player_body():
	if direction != Vector3.ZERO && current_speed > 0 && camera_controller.current_camera != camera_controller.camera_1p:
		var camera_yaw = atan2(camera_controller.global_transform.basis.z.x, camera_controller.global_transform.basis.z.z)
		$body.rotation.y = camera_yaw + PI # Add PI to make the player face the same direction as the camera
