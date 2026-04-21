extends Node
class_name ActionHandler

# nodes
@onready var parent: Mob = $"../"
@onready var anim_tree: AnimationTree = $"../AnimationTree"
@onready var combat_controller = $CombatController
@onready var action_controller = $BodyActionController
@onready var movement_controller = $MovementController
@onready var idle_controller = $IdleController

@onready var arm_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/ArmAnims/playback"]
@onready var body_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/BodyAnims/playback"]
@onready var face_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/FaceAnims/playback"]

@onready var idle_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/BodyAnims/Idle/playback"]
@onready var action_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/BodyAnims/Action/playback"]
@onready var movement_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/BodyAnims/Movement/playback"]
@onready var body_idle_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/BodyAnims/BodyIdles/playback"]

@onready var attack_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/ArmAnims/Attack/playback"]
@onready var block_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/ArmAnims/Block/playback"]
@onready var draw_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/ArmAnims/DrawWeapon/playback"]

@onready var face_idle_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/FaceAnims/Idle/playback"]
@onready var face_emotion_state_machine: AnimationNodeStateMachinePlayback = anim_tree["parameters/FaceAnims/Emotion/playback"]

# body blends
var arm_blend:float: # 0 = Body, 1 = Arm
	set(value):
		arm_blend = value
		var tween := create_tween() # smoothly transition to arm anims
		tween.tween_property(anim_tree,"parameters/ArmBlend/blend_amount",value,.3)
var face_blend:float:
	set(value):
		face_blend = value
		anim_tree["parameters/FaceBlend/blend_amount"] = value
var mouth_blend:float: # TODO not used
	set(value):
		mouth_blend = value
		anim_tree["parameters/MouthBlend/blend_amount"] = value

# TODO combat current controller is disabled. remember to set Combat blockers not by vur contr, but by arm_blend

# speed modifier animations
const press_speed_modifiers := {"Roll":2, "Attack":.1}
const hold_speed_modifiers := {"Run":3, "Block":.2}

# keys informations
enum CombatKeys{DrawWeapon, Attack, Block}
enum MovementKeys{Up, Down, Left, Right, Sprint}
enum ActionKeys{Roll, Jump}
enum MobControllers {Action, Combat, Movement, Idle}

# INIT PATHS
func _ready():
	arm_blend = anim_tree["parameters/ArmBlend/blend_amount"]
	face_blend = anim_tree["parameters/FaceBlend/blend_amount"]
	mouth_blend = anim_tree["parameters/MouthBlend/blend_amount"]

# trigger action on a frame TODO used only for jump. can be done simpler
func check_frame():
	if body_state_machine.get_current_node() == "Action":
		action_controller.check_frame()

# SIGNALS
func _on_animation_tree_animation_finished(anim_name:String):
	if anim_name == "Die":
		set_physics_process(false)
		return
	
	elif anim_name.begins_with("GeneralAnimations") && idle_controller.performing_event:
		idle_controller.on_animation_finished(anim_name)
	elif anim_name.begins_with("CombatAnimations"):
		combat_controller.on_animation_finished(anim_name)
	elif anim_name.begins_with("GeneralAnimations"):
		action_controller.on_animation_finished(anim_name)
