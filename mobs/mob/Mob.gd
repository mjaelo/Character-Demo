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
var direction := Vector3()
var current_speed := 10
var normal_speed := 10 # TODO rename to speed
var jump_impulse := 21
var gravity := 30
var speed_limit := 100

# nodes
@onready var action_handler:ActionHandler = $ActionHandler

# TODO
	# skip?
		# allow armanims to move legs when not moving
		# anims: spirits float idle?  Statues freeze idle?
		# feather hat partly missing feather
		# shoe sometimes has shape key for some reason
		# often tpose for a sec on arm action - maybe change blend shape when cur anim len > 0?
		# make spirits semi transparent?
	# after deleting a preset, warning on save preset should be gone
	# new structure
		# on game start, slight fall
		# often cant block when walking... common bug

func _physics_process(delta):
	# trigger combat / body action action on a frame
	action_handler.check_frame()
	
	action_handler.idle_controller.handle_idle(delta)
	
	if self is Player:
		(self as Player).handle_player_input(delta)
	
	# Move
	move_and_slide()
