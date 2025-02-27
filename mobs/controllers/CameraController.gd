extends Node3D

var sensitivity = 5#1 #TODO add to settings
var camera_rot = Vector3.ZERO
var move_with_right_click := false

@onready var mob:Mob = $"../../Mob"
@onready var camera_1p:Camera3D = $"1PCamera"
@onready var camera_3p:Camera3D = $"SpringArm3D/3PCamera"
@onready var current_camera:Camera3D = camera_3p:
	set(value):
		current_camera.current = false
		current_camera = value
		current_camera.current = true

func _process(_delta):
	var parent_pos = mob.global_transform.origin
	global_transform.origin = parent_pos

func _input(event):
	if Input.is_key_pressed(KEY_L): # TODO not L. when zoom. maybe other shortcut.
		switch_cameras()
	
	if event is InputEventMouseMotion:
		rotate_camera(event)
	elif event is InputEventMouseButton && current_camera != camera_1p:
		handle_zoom(event)
	
	# rotate player model to camera when moving
	#if mob.direction != Vector3.ZERO && mob..speed > 0:
		#var camera_yaw = atan2(camera_rot.z.x, camera_rot.z.z)
		#mob..get_node("body").rotation.y = camera_yaw + PI # Add PI to make the player face the same direction as the camera
	

func switch_cameras():
	current_camera = camera_1p if current_camera == camera_3p else camera_3p
	
func rotate_camera(event:InputEventMouseMotion):
	# enforce right click to move camera (in char creator)
	# TODO () when connected to game, delete it. only used for testing movements in char creator
	if move_with_right_click && !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return
	
	#if current_camera == camera_3p:
	var xRot = clamp(camera_rot.x - event.relative.y/1000*sensitivity,-0.9,0.5)
	var yRot = camera_rot.y - event.relative.x/1000*sensitivity
	camera_rot = Vector3(xRot,yRot,0)
	rotation = camera_rot
	#else:
		#mob.rotate_y(-event.relative.x*.01)
		#rotate_y(-event.relative.x*.01)
		#rotate_z(-event.relative.y*.01)
		#rotation.z = clamp(
			#rotation.z,
			#deg_to_rad(-30),
			#deg_to_rad(60)
			#)

func handle_zoom(event:InputEventMouseButton):
	var base = $SpringArm3D
	var spring_arm_length = base.spring_length
	var button_id = event.button_index
	
	if button_id == 5: # scroll up
		if spring_arm_length< 20:
			base.spring_length += 0.2

	if button_id == 4: # scroll donw
		if spring_arm_length> .5:
			base.spring_length -= 0.2
