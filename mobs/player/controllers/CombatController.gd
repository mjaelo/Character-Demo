extends Node

# sheave unsheave
var hip_slot:Node3D
var back_slot:Node3D
var r_hand_slot:Node3D
var l_hand_slot:Node3D
var sword:Node3D
var shield:Node3D
var weapon_drawn := false # TODO () mobs react negatively to it? change to is_dangerous, to fit with unarmed creatures?

@onready var parent: Player

# trigger action on a frame
var frame_trigger:= {
	"DrawHip": {"treshold": .25,"prev": 0,"action": func (): attach_item_to_bone(r_hand_slot,sword)},
	"DrawBack": {"treshold": .25,"prev": 0,"action": func (): attach_item_to_bone(l_hand_slot,shield)}
	}

func _ready():
	parent = $"../../Mob"
	var skeleton:Skeleton3D = parent.get_node("body/Armature/Skeleton3D")
	
	hip_slot = skeleton.get_node("Hip/HipContainer")
	back_slot = skeleton.get_node("Back/BackContainer")
	r_hand_slot = skeleton.get_node("Right Hand/HandContainer")
	l_hand_slot = skeleton.get_node("Left Hand/HandContainer")
	sword = skeleton.get_node("Hip/HipContainer/Sword")
	shield = skeleton.get_node("Back/BackContainer/Shield")

func sheave_hip():
	parent.arm_states.travel("PutHip")

func sheave_back():
	print(parent.body_blend)
	parent.body_blend = 1
	parent.arm_states.travel("PutBack")
	
func unsheave_hip():
	parent.arm_states.travel("DrawHip")

func unsheave_back():
	print(parent.body_blend)
	parent.body_blend = 1
	parent.arm_states.travel("DrawBack")

func attach_item_to_bone(new_slot:Node3D, item:Node3D):
	if item:
		var item_parent = item.get_parent()
		item_parent.remove_child(item)
		new_slot.add_child(item)
		item.position = Vector3.ZERO
		item.rotation_degrees = Vector3.ZERO

# SIGNALS (or external calls)
func _on_combat_action_released(action_name: String):
	if action_name == "Block":
		parent.body_blend = 0
		# TODO Slow down

func _on_combat_action_pressed(action_name: String):
	parent.body_blend = 1
	if action_name == "Attack" && !weapon_drawn:
		unsheave_hip()
	elif action_name == "Sheave":
		if !weapon_drawn:
			unsheave_hip()
		else:
			sheave_hip()
	else:
		parent.arm_states.travel(action_name)

func _on_combat_animation_finished(anim_name: String):
	parent.body_blend = 0
	if anim_name == "DrawBack":
		if weapon_drawn:
			attach_item_to_bone(back_slot,shield)
		weapon_drawn = !weapon_drawn
	
	elif anim_name == "DrawHip":
		if weapon_drawn:
			attach_item_to_bone(hip_slot, sword)
		
		if shield.visible:
			if weapon_drawn:
				sheave_back()
			else:
				unsheave_back()
		else:
			weapon_drawn = !weapon_drawn


func _on_weapon_body_entered(body):
	if weapon_drawn && body != parent && body is CharacterBody3D && !$"../../".arm_non_attacking_states.has($"../../".arm_states.get_current_node()):
		body.queue_free()
