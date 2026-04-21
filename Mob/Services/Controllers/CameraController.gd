extends Node3D

var sensitivity = UIConstants.GAME_CAMERA_SENSITIVITY

@onready var mob := $"../../Mob"
@onready var base := $SpringArm3D
@onready var camera_1p := $"1PCamera"
@onready var camera_3p := $"SpringArm3D/3PCamera"
@onready var current_camera := camera_3p:
	set(value):
		current_camera.current = false
		current_camera = value
		current_camera.current = true

var head_mesh_visibility := {
	"Hair":true,"Beard":true,"Brows":true,"Eyelashes":true,"Hat":true,"Eyes":true
}
func update_head_mesh_visibility(mob:Mob): # TODO should read body / eq data instead. what if no helmet then suddenly helmet?
	for key in head_mesh_visibility.keys():
		head_mesh_visibility[key] = mob.get_node("body/Armature/Skeleton3D/" +key).visible

func _process(_delta):
	var parent_pos = mob.global_transform.origin
	global_transform.origin = parent_pos

func handle_input(event:InputEvent):
	if Input.is_action_just_pressed("Switch Camera"):
		switch_cameras()
	
	elif event is InputEventMouseMotion:
		rotate_camera(event)
	elif event is InputEventMouseButton:
		handle_zoom(event)

func switch_cameras():
	if current_camera == camera_3p:
		update_head_mesh_visibility(mob)
	
	current_camera = camera_1p if current_camera == camera_3p else camera_3p
	mob.scale += Vector3(0,-.15,0) if  current_camera == camera_3p else Vector3(0,.15,0)
	
	# hide head meshes for fp cam
	for mesh_name in head_mesh_visibility.keys():
		var mesh:MeshInstance3D = mob.get_node("body/Armature/Skeleton3D/"+mesh_name)
		mesh.visible = current_camera == camera_3p && head_mesh_visibility[mesh_name]
	
	mob.get_node("body/Armature").rotation.y = deg_to_rad(180) if current_camera == camera_1p else deg_to_rad(0)
	mob.get_node("body").rotation = rotation if current_camera == camera_1p else Vector3.ZERO
	
func rotate_camera(event:InputEventMouseMotion):
	rotation = Vector3(
		clamp(rotation.x - event.relative.y/1000*sensitivity,-0.9,0.5),
		rotation.y - event.relative.x/1000*sensitivity,
		0
	)
	if current_camera == camera_1p:
		mob.get_node("body").rotation = rotation # TODO rotate just spine to see feet?

func handle_zoom(event:InputEventMouseButton):
	var button_id = event.button_index
	var spring_arm_length = base.spring_length
	
	if current_camera == camera_3p:
		if button_id ==  MOUSE_BUTTON_WHEEL_DOWN && spring_arm_length < 5: # scroll up (out)
			base.spring_length += 0.02*sensitivity
		if button_id == MOUSE_BUTTON_WHEEL_UP: # scroll donw (in)
			if spring_arm_length > -1:
				base.spring_length -= 0.02*sensitivity
			else:
				switch_cameras()
	elif current_camera == camera_1p && button_id == 5: # scroll up (out)
		switch_cameras()
