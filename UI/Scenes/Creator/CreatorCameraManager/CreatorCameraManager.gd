extends Control

@onready var player_camera_controller := $"../../Player/Controllers/CameraController"
@onready var player_camera_3p_spring := $"../../Player/Controllers/CameraController/SpringArm3D"
@onready var player_camera_1p := $"../../Player/Controllers/CameraController/1PCamera"
@onready var camera_height := $HBoxContainer/CameraHeight

var propagated_event:InputEventMouse

const camera_buttons := {
	"Zoom":{
		"ZoomIn": MOUSE_BUTTON_WHEEL_UP,
		"ZoomOut": MOUSE_BUTTON_WHEEL_DOWN
	},
	"Rotate":{
		"Rotate-T": Vector2(0,1),
		"Rotate-B": Vector2(0,-1),
		"Rotate-L": Vector2(1,0),
		"Rotate-R": Vector2(-1,0) 
	}
}

func _ready() -> void:
	player_camera_controller.sensitivity = UIConstants.CREATOR_CAMERA_SENSITIVITY
	$"../../Player/Mob/body".rotation.y = 0
	player_camera_3p_spring.transform.origin.z += UIConstants.CREATOR_CAMERA_ZOOM_OFFSET
	camera_height.max_value = UIConstants.CAMERA_MAX_HEIGHT
	camera_height.value = MobConstants.race_cam_height.call(MobConstants.MobRaces.Human)
	
	# connect camera signals
	for button_name in camera_buttons.Zoom.keys():
		var zoom_button:Button = find_child(button_name)
		var button_id:int = camera_buttons.Zoom[button_name]
		zoom_button.button_down.connect(_on_zoom_button_down.bind(button_id))
		zoom_button.button_up.connect(_on_camera_button_up)
	
	for button_name in camera_buttons.Rotate.keys():
		var rotate_button:TextureButton = find_child(button_name)
		var rotate_dir:Vector2 = camera_buttons.Rotate[button_name]
		rotate_button.button_down.connect(_on_rotate_button_down.bind(rotate_dir))
		rotate_button.button_up.connect(_on_camera_button_up)

func editor_event_in_limits(event:InputEventMouseButton) -> bool: 
	return event.button_index != MOUSE_BUTTON_WHEEL_UP || player_camera_3p_spring.spring_length > -1

# processes
func _process(delta: float) -> void:
	if propagated_event && (!propagated_event is InputEventMouseButton || editor_event_in_limits(propagated_event)):
		player_camera_controller.handle_input(propagated_event)

func _unhandled_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton && editor_event_in_limits(event)) || (event is InputEventMouseMotion && Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)):
		player_camera_controller.handle_input(event)

# functions
func set_camera_height_by_race(race:int):
	camera_height.value = MobConstants.race_cam_height.call(race)

# signals
func _on_rotate_button_down(rotate_direction:Vector2) -> void:
	var rotate_event := InputEventMouseMotion.new()
	rotate_event.relative = rotate_direction
	propagated_event = rotate_event

func _on_zoom_button_down(button_id:int) -> void:
	var scroll_event := InputEventMouseButton.new()
	scroll_event.button_index = button_id
	propagated_event = scroll_event

func _on_camera_button_up() -> void:
	propagated_event = null

func _on_camera_height_value_changed(value: float) -> void:
	player_camera_3p_spring.transform.origin.y = value
	player_camera_1p.transform.origin.y = value

func _on_rotate_reset_pressed() -> void:
	player_camera_controller.rotation = Vector3.ZERO

func _on_start_game_pressed() -> void:
	player_camera_controller.sensitivity = UIConstants.GAME_CAMERA_SENSITIVITY
	set_camera_height_by_race($"../".mob_data.race)
	$"../".start_game()
