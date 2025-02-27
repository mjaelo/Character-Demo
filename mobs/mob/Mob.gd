extends CharacterBody3D
class_name Mob

# MobData TODO () set it
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

const press_speed_modifiers := {"Roll":2,"Attack":.1}
const hold_speed_modifiers := {"Run":3,"Block":.2}
const arm_non_attacking_states := ["Block","Idle"]


# TODO
	# skip?
		# allow armanims to move legs when not moving
		# actions are often not called
		# tpose often on arm action - change blend shape when cur anim len > 0?
	# CAMERA
		# 1P cam in Player chest.
		# separate 3P cam for editor and gameplay?
		# auto adjust cam height for ogres and spirits
	# FIX:
		# hat removes baldness
		# ogre outfit and accesories are handled like a normal outfit
		# handle get_mob_data differently
			# 
	# races:
		# pick race tagged clothes
		# use same asset for get_r_data and adjust_md_to_r
		# anims: spirits always fall? statue freeze idle?
		# spirit eyes not shiny enough. (change iris, like with statues?)


# INIT
func _ready():
	body_blend = anim_tree["parameters/UpperBlend/blend_amount"]
	body_states = anim_tree["parameters/BodyAnims/playback"]
	arm_states = anim_tree["parameters/ArmAction/playback"]
	idle_states = anim_tree["parameters/BodyAnims/Idle/playback"]
	action_states = anim_tree["parameters/BodyAnims/Action/playback"]
	move_states = anim_tree["parameters/BodyAnims/Movement/playback"]
	#if race == MobConstants.MobRaces.Statue:
		#anim_tree.active = false

# adjust mob model in a way not covered by body and eq data
func adjust_mob_to_race(race_i:int):
	race = race_i
	var dict:Dictionary =  MobConstants.race_action_dict[race_i]
	var skeleton = $body/Armature/Skeleton3D
	# show_monster_body
	var show_monster_body:bool = dict.has("show_monster_body") && dict.show_monster_body
	skeleton.get_node("monster-body").visible = show_monster_body
	const body_meshes := ["Body","Eyelashes","Brows","Eyes"] # meshes outside bodydata
	for child in skeleton.get_children():
		if body_meshes.has(child.name):
			child.visible = !show_monster_body
	
	# change scale
	scale = Vector3.ONE if !dict.has("scale") else Vector3.ONE*dict.scale
	
	# disable details texture on body for statues
	var body_mesh:MeshInstance3D = skeleton.get_node("Body")
	var material:StandardMaterial3D = body_mesh.get_active_material(0)
	material.albedo_texture_msdf = [MobConstants.MobRaces.Statue,MobConstants.MobRaces.Spirit].has(race)
	
	# change body colors outside of body_data
	var def_body_colors := {"Eyes": {0:Color.WHITE, 2:Color.BLACK}, "Eyelashes":{0:Color.BLACK}}
	def_body_colors.Eyes[0]=Color.WHITE if !dict.has("eye_whites") else dict.eye_whites
	# set colors to all meshes outside body data
	for mesh_name in def_body_colors.keys():
		for mat_nr in def_body_colors[mesh_name].keys():
			var color = def_body_colors[mesh_name][mat_nr] if race != MobConstants.MobRaces.Statue else MobConstants.Statue_Grey
			MobUtils.set_mesh_color(color, skeleton.get_node(mesh_name),mat_nr)
	if anim_tree:
		anim_tree.active = race != MobConstants.MobRaces.Statue

func _physics_process(delta):
	# trigger action on a frame
	if body_states.get_current_node() == "Action":
		check_frame(action_controller.frame_trigger, action_states.get_current_play_position(), action_states.get_current_node())
	elif body_blend > 0:
		check_frame(combat_controller.frame_trigger, arm_states.get_current_play_position(), arm_states.get_current_node())
	
	if movement_controller:
		velocity = movement_controller.handle_movement(delta, velocity)
	
	# Move
	move_and_slide()
	
	# TODO move somewhere else. actions dont work
	#if race == MobConstants.MobRaces.Spirit:
		#if move_states.is_playing():
			#body_states.start("Idle")
		#idle_states.travel("Fall")
		#arm_states.travel("Idle")
		#body_blend = 1

# trigger action on a frame
func check_frame(frame_trigger:Dictionary, play_pos:float, action_name:String):
	if frame_trigger.has(action_name):
		var info = frame_trigger[action_name]
		if info.prev <= info.treshold && info.treshold < play_pos:
			info.action.call()
		info.prev = play_pos

# SIGNALS
func _on_animation_tree_animation_started(anim_name):
	#if race == MobConstants.MobRaces.Statue && (IdleActions.has(anim_name)) && body_blend:
		#anim_tree.active = false
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
