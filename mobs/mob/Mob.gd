extends CharacterBody3D
class_name Mob

# MobData
var mob_name: String
var race: int
var type: int
var gender: int
var body_data: BodyData
var equipment_data: EquipmentData

# movement
var speed := 10
var normal_speed := 10
var jump_impulse := 21
var gravity := 30

# nodes
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var combat_controller = $Controllers/CombatController
@onready var action_controller = $Controllers/ActionController
@onready var movement_controller = $"../Controllers/MovementController"

var arm_states: AnimationNodeStateMachinePlayback
var body_states: AnimationNodeStateMachinePlayback
var idle_states: AnimationNodeStateMachinePlayback
var action_states: AnimationNodeStateMachinePlayback
var move_states: AnimationNodeStateMachinePlayback

var blocking := false

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

enum MobState {Arm, Action, Idle, Movement}
var current_state := MobState.Idle

const press_speed_modifiers := {"Roll":2, "Attack":.1}
const hold_speed_modifiers := {"Run":3, "Block":.2}
const damaging_states := ["Attack", "AttackSword"]

# TODO
	# skip?
		# allow armanims to move legs when not moving
		# anims: spirits float idle?  Statues freeze idle?
		# feather hat partly missing feather
		# shoe sometimes has shape key for some reason
		# often tpose for a sec on arm action - maybe change blend shape when cur anim len > 0?
		# make spirits semi transparent?
		# add loading screen?
		# add undo button - cant duplicate node (editing org, edits new)

# INIT
func _ready():
	body_blend = anim_tree["parameters/UpperBlend/blend_amount"]
	body_states = anim_tree["parameters/BodyAnims/playback"]
	arm_states = anim_tree["parameters/ArmAction/playback"]
	idle_states = anim_tree["parameters/BodyAnims/Idle/playback"]
	action_states = anim_tree["parameters/BodyAnims/Action/playback"]
	move_states = anim_tree["parameters/BodyAnims/Movement/playback"]

func _physics_process(delta):
	# trigger action on a frame
	if current_state == MobState.Action:
		check_frame(action_controller.frame_trigger, action_states.get_current_play_position(), action_states.get_current_node())
	elif body_blend > 0:
		check_frame(combat_controller.frame_trigger, arm_states.get_current_play_position(), arm_states.get_current_node())
	
	if movement_controller:
		velocity = movement_controller.handle_movement(delta, velocity)
	
	# Move
	move_and_slide()

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
	elif anim_name == "Die":
		set_physics_process(false)
