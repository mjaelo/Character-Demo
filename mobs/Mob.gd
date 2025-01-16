extends CharacterBody3D
class_name Mob

# movement
var speed := 10
var normal_speed := 10
var jump_impulse := 21
var gravity := 30

# nodes
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var combat_controller = $"../Controllers/CombatController"
@onready var movement_controller = $"../Controllers/MovementController"
@onready var action_controller = $"../Controllers/ActionController"

var arm_states: AnimationNodeStateMachinePlayback
var body_states: AnimationNodeStateMachinePlayback
var idle_states: AnimationNodeStateMachinePlayback
var action_states: AnimationNodeStateMachinePlayback
var move_states: AnimationNodeStateMachinePlayback

var blocking:bool = false

var body_blend:float: # 0 = Body, 1 = Arm
	set(value):
		body_blend = value
		var tween := create_tween() # smoothly transition to arm anims
		tween.tween_property(anim_tree,"parameters/UpperBlend/blend_amount",value,.3)

# enums
enum ArmActions{Block,Attack,Shoot,DrawBack,DrawHip	,Sheave} # Sheave isnt an animation, just action
enum IdleActions{Idle,Fall}
enum MoveActions{Walk, Run, Up, Down, Left, Right}
enum BodyActions{Roll,Jump}

const press_speed_modifiers := {"Roll":2,"Attack":.1}
const hold_speed_modifiers := {"Run":3,"Block":.2}
const arm_non_attacking_states := ["Block","Idle"]

# INIT
func _ready():
	body_blend = anim_tree["parameters/UpperBlend/blend_amount"]
	body_states = anim_tree["parameters/BodyAnims/playback"]
	arm_states = anim_tree["parameters/ArmAction/playback"]
	idle_states = anim_tree["parameters/BodyAnims/Idle/playback"]
	action_states = anim_tree["parameters/BodyAnims/Action/playback"]
	move_states = anim_tree["parameters/BodyAnims/Movement/playback"]

# trigger action on a frame
func check_frame(frame_trigger:Dictionary, play_pos:float, action_name:String):
	if frame_trigger.has(action_name):
		var info = frame_trigger[action_name]
		if info.prev <= info.treshold && info.treshold < play_pos:
			info.action.call()
		info.prev = play_pos

# SIGNALS
func _on_animation_tree_animation_started(anim_name):
	if press_speed_modifiers.has(anim_name):
		speed = normal_speed * press_speed_modifiers[anim_name]
		
func _on_animation_tree_animation_finished(anim_name:String):
	if press_speed_modifiers.has(anim_name):
		speed = normal_speed
	
	if ArmActions.keys().has(anim_name):
		combat_controller._on_combat_animation_finished(anim_name)
	elif BodyActions.keys().has(anim_name):
		action_controller._on_body_action_finished(anim_name)
