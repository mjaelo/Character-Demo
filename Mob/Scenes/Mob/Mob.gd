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
var current_speed := GeneralConstants.DEFAULT_SPEED
var normal_speed := GeneralConstants.DEFAULT_SPEED
var jump_impulse := GeneralConstants.DEFAULT_JUMP_IMPULSE
var gravity := GeneralConstants.DEFAULT_GRAVITY
var speed_limit := GeneralConstants.DEFAULT_SPEED_LIMIT

# nodes
@onready var action_handler:ActionHandler = $ActionHandler

func _physics_process(delta):
	# trigger combat / body action action on a frame
	action_handler.check_frame()
	
	action_handler.idle_controller.handle_idle(delta)
	_handle_input(delta)
	
	# Move
	move_and_slide()

# Override in Player for player-specific input handling
func _handle_input(_delta: float):
	pass
