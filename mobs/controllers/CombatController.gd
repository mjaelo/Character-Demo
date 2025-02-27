extends Node

# sheave unsheave
var hip_slot:Node3D
var back_slot:Node3D
var r_hand_slot:Node3D
var l_hand_slot:Node3D
var sword:Node3D
var shield:Node3D
var weapon_drawn := false # TODO () mobs react negatively to it? change to is_dangerous, to fit with unarmed creatures?

@onready var parent: Mob

# trigger action on a frame
var frame_trigger:= {
	"DrawHip": {"treshold": .25,"prev": 0,"action": func (): attach_item_to_bone(r_hand_slot,sword)},
	#"DrawBack": {"treshold": .01,"prev": 0,"action": func (): attach_item_to_bone(l_hand_slot,shield)}
	}

func _ready():
	parent = $"../../"
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
	# unsheave sword
	if action_name == "Attack" && !weapon_drawn:
		if sword.visible:
			unsheave_hip()
		# on bare hands, just attack
		else:
			attach_item_to_bone(r_hand_slot,sword)
			weapon_drawn = !weapon_drawn
			parent.arm_states.travel(action_name)
	# sheave/unsheave sword
	elif action_name == "Sheave" && sword.visible:
		if !weapon_drawn:
			unsheave_hip()
		else:
			sheave_hip()
	elif action_name == "Block":
		if shield.visible:
			parent.arm_states.travel(action_name)
		elif sword.visible:
			parent.arm_states.travel("BlockSword")
		else:
			parent.body_blend = 0
			return
	else:
		parent.arm_states.travel(action_name)

func _on_combat_animation_finished(anim_name: String):
	parent.body_blend = 0
	if anim_name == "DrawBack":
		if weapon_drawn:
			attach_item_to_bone(back_slot,shield)
		else:
			attach_item_to_bone(l_hand_slot,shield)
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
	if weapon_drawn && body != parent && body is Mob && !parent.arm_non_attacking_states.has(parent.arm_states.get_current_node()):
		(body as Mob).idle_states.travel("Die")
		body.get_node("CollisionShape3D").queue_free()
