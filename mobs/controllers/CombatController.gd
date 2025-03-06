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

#func sheave_hip():
	#parent.arm_states.travel("PutHip")
#
#func sheave_back():
	#parent.body_blend = 1
	#parent.arm_states.travel("PutBack")
#
#func unsheave_hip():
	#parent.arm_states.travel("DrawHip")
#
#func unsheave_back():
	#parent.body_blend = 1
	#parent.arm_states.travel("DrawBack")

func attach_item_to_bone(new_slot:Node3D, item:Node3D):
	if item:
		var item_parent = item.get_parent()
		item_parent.remove_child(item)
		new_slot.add_child(item)
		item.position = Vector3.ZERO
		item.rotation_degrees = Vector3.ZERO

func end_action():
	parent.body_blend = 0
	parent.current_state = parent.MobState.Idle

func execute_action(action:String):
	if action == "":
		pass
	
	parent.arm_states.travel(action)

func toggle_weapons():
	if sword.visible:
		var action := "PutHip" if weapon_drawn else "DrawHip"
		execute_action(action)
	elif shield.visible:
		var action := "PutBack" if weapon_drawn else "DrawBack"
		execute_action(action)
	else:
		end_action()

func block():
	if shield.visible:
		execute_action("Block")
	elif sword.visible:
		execute_action("BlockSword")
	else:
		end_action()

func attack():
	attach_item_to_bone(r_hand_slot,sword)
	execute_action("Attack")

# SIGNALS (or external calls)
func _on_combat_action_released(action_name: String):
	# TODO make block go to idle in arm_states, otherwise when block again, anim wont go from start
	if action_name == "Block" && ["Block","BlockSword"].has(parent.arm_states.get_current_node()):
		end_action()

func _on_combat_action_pressed(action_name: String):
	# prepare for anims
	parent.body_blend = 1
	parent.current_state = parent.MobState.Arm
	
	# actions - weapon not drawn
	if !weapon_drawn:
		if action_name == "Attack" && !sword.visible:
			attack()
		else: # unsheave weapons
			toggle_weapons()
	
	# actions - weapon drawn
	else:
		if action_name == "Attack":
			attack()
		elif action_name == "Block":
			block()
		else: # sheave weapons
			toggle_weapons()

func _on_combat_animation_finished(anim_name: String):
	if anim_name == "DrawHip":
		if weapon_drawn:
			attach_item_to_bone(hip_slot, sword)
		
		if shield.visible:
			var action := "PutBack" if weapon_drawn else "DrawBack"
			execute_action(action)
		else:
			weapon_drawn = !weapon_drawn
			end_action()
	
	elif anim_name == "DrawBack":
		attach_item_to_bone(
			back_slot if weapon_drawn else l_hand_slot,
			shield
		)
		weapon_drawn = !weapon_drawn
		end_action()

func _on_weapon_body_entered(body):
	if weapon_drawn && body != parent && body is Mob && parent.damaging_states.has(parent.arm_states.get_current_node()):
		(body as Mob).idle_states.travel("Die")
		body.get_node("CollisionShape3D").queue_free()
