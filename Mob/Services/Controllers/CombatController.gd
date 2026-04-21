extends Node

# node paths
@onready var parent_mob:Mob = $"../../"
@onready var parent_controller:ActionHandler = $"../"

# sheave unsheave
@onready var hip_slot:Node3D = $"../../body/Armature/Skeleton3D/Hip/HipContainer"
@onready var back_slot:Node3D = $"../../body/Armature/Skeleton3D/Back/BackContainer"
@onready var r_hand_slot:Node3D = $"../../body/Armature/Skeleton3D/Right Hand/HandContainer"
@onready var l_hand_slot:Node3D = $"../../body/Armature/Skeleton3D/Left Hand/HandContainer"
@onready var sword:MeshInstance3D = $"../../body/Armature/Skeleton3D/Hip/HipContainer/Sword"
@onready var shield:MeshInstance3D = $"../../body/Armature/Skeleton3D/Back/BackContainer/Shield"

# other variables
var weapon_drawn := false

func attach_item_to_bone(new_slot:Node3D, item:Node3D):
	if !item:
		return
	var item_parent = item.get_parent()
	item_parent.remove_child(item)
	new_slot.add_child(item)
	item.position = Vector3.ZERO
	item.rotation_degrees = Vector3.ZERO

func execute_action(action_type:int, action:String):
	parent_controller.arm_blend = 1
	parent_controller.arm_state_machine.travel(parent_controller.CombatKeys.keys()[action_type])
	var arm_state_dict := {
		parent_controller.CombatKeys.Attack: parent_controller.attack_state_machine,
		parent_controller.CombatKeys.Block: parent_controller.block_state_machine,
		parent_controller.CombatKeys.DrawWeapon: parent_controller.draw_state_machine
	}
	arm_state_dict[action_type].travel(action)

func toggle_weapons():
	if sword.visible:
		execute_action(parent_controller.CombatKeys.DrawWeapon, "DrawHip")
	elif shield.visible:
		execute_action(parent_controller.CombatKeys.DrawWeapon, "DrawBack")
	else:
		parent_controller.arm_blend = 0

func block():
	if shield.visible:
		execute_action(parent_controller.CombatKeys.Block, "BlockShield")
		parent_mob.current_speed = parent_mob.normal_speed * parent_controller.hold_speed_modifiers["Block"]
	elif sword.visible:
		execute_action(parent_controller.CombatKeys.Block, "BlockSword")
		parent_mob.current_speed = parent_mob.normal_speed * parent_controller.hold_speed_modifiers["Block"]
	else:
		parent_controller.arm_blend = 0

func attack():
	execute_action(parent_controller.CombatKeys.Attack, "AttackSword")
	parent_mob.current_speed = parent_mob.normal_speed * parent_controller.press_speed_modifiers["Attack"]

# EXTERNAL SIGNALS
func on_action_pressed(action_name: String):
	var action_id:int = parent_controller.CombatKeys.keys().find(action_name)
	
	# actions - weapon not drawn
	if !weapon_drawn:
		if action_id == parent_controller.CombatKeys.Attack && !sword.visible:
			attach_item_to_bone(r_hand_slot,sword)
			attack()
		else: # unsheave weapons
			toggle_weapons()
	
	# actions - weapon drawn
	else:
		if action_id == parent_controller.CombatKeys.Attack:
			attack()
		elif action_id == parent_controller.CombatKeys.Block:
			block()
		else: # sheave weapons
			toggle_weapons()

func on_action_released(action_name: String):
	if action_name == "Block" && parent_controller.arm_state_machine.get_current_node() == "Block":
		parent_controller.arm_state_machine.travel("Idle")
		parent_controller.arm_blend = 0

func on_animation_finished(anim_name: String):
	if anim_name.contains("DrawHip"):
		if parent_controller.draw_state_machine.get_current_node() == "ReturnHip":
			attach_item_to_bone(hip_slot if weapon_drawn else r_hand_slot, sword)
		else:
			if shield.visible:
				execute_action(parent_controller.CombatKeys.DrawWeapon, "PutBack")
			else:
				weapon_drawn = !weapon_drawn
				parent_controller.arm_blend = 0
	
	elif anim_name.contains("DrawBack"):
		if parent_controller.draw_state_machine.get_current_node() == "ReturnBack":
			attach_item_to_bone(back_slot if weapon_drawn else l_hand_slot,	shield)
		else:
			weapon_drawn = !weapon_drawn
			parent_controller.arm_blend = 0
	
	if anim_name.contains("Attack"):
		parent_controller.arm_blend = 0 # TODO is it needed?

# INTERNAL SIGNALS
func _on_weapon_body_entered(body):
	if body != parent_mob && body is Mob && parent_controller.attack_state_machine.is_playing():
		(body as Mob).action_handler.idle_state_machine.travel("Die")
		body.get_node("CollisionShape3D").queue_free()
