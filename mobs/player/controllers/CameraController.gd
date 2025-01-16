extends Node3D

var sensitivity = 5#1 #TODO add to settings
var camera_rot = Vector3.ZERO
var move_with_right_click := false

func _process(_delta):
	var parent_pos = $"../../".global_transform.origin
	global_transform.origin = parent_pos

func _input(event):
		if event is InputEventMouseMotion:
			# enforce right click to move camera (in char creator)
			if move_with_right_click && !Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):# TODO () when connected to game, delete it. only used for testing movements in char creator
				return
			var xRot = clamp(camera_rot.x - event.relative.y/1000*sensitivity,-0.9,0.5)
			var yRot = camera_rot.y - event.relative.x/1000*sensitivity
			camera_rot = Vector3(xRot,yRot,0)
			rotation = camera_rot
		
		if event is InputEventMouseButton:
			var spring_arm_length = get_node("SpringArm3D").spring_length
			var button_id = event.button_index
			
			if button_id ==5: # scroll up
				if spring_arm_length< 20:
					get_node("SpringArm3D").spring_length +=0.2

			if button_id ==4: # scroll donw
				if spring_arm_length> .5:
					get_node("SpringArm3D").spring_length -=0.2
