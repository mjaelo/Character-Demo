extends Node

@onready var parent_mob: Mob = $"../../"
@onready var parent_controller: ActionHandler = $"../"

var face_idle_probability := 0.2
var body_idle_probability := 0.08

enum IdleFaceAnims { FaceLookAround, FaceLookDown, FaceBlinking }
enum IdleBodyAnims { IdleLookAround, IdleStretchArms, IdleStretchNeck }

var performing_event := false:
	set(value):
		performing_event = value
		if !idle_event_timer:
			return
		if value:
			idle_event_timer.stop()
		else:
			idle_event_timer.start()

var idle_event_timer: Timer

func _ready() -> void:
	call_deferred("setup_timer")

func setup_timer():
	idle_event_timer = Timer.new()
	idle_event_timer.timeout.connect(handle_idle_event)
	add_child(idle_event_timer)
	idle_event_timer.start(2.0)

func facial_idle():
	parent_controller.face_blend = 1
	parent_controller.face_state_machine.travel("Idle")
	parent_controller.face_idle_state_machine.travel(IdleFaceAnims.keys().pick_random())
	performing_event = true

func body_idle():
	parent_controller.body_state_machine.travel("BodyIdles")
	parent_controller.body_idle_state_machine.travel(IdleBodyAnims.keys().pick_random())
	performing_event = true

func handle_idle(delta: float):
	var desired_state := "Idle"
	if !parent_mob.is_on_floor():
		if parent_mob.velocity.y < parent_mob.speed_limit:
			parent_mob.velocity.y -= parent_mob.gravity * delta
		desired_state = "Fall"
		performing_event = false

	if desired_state != parent_controller.idle_state_machine.get_current_node():
		parent_controller.idle_state_machine.travel(desired_state)

func handle_idle_event():
	if performing_event || !is_node_ready():
		if parent_controller.face_idle_state_machine.get_current_node() == "End" \
				&& parent_controller.body_idle_state_machine.get_current_node() == "End":
			push_warning("IdleController: performing_event stuck, resetting.")
			performing_event = false
		return

	if randf() < face_idle_probability:
		facial_idle()
	if randf() < body_idle_probability:
		body_idle()

# EXTERNAL SIGNALS
func on_animation_finished(anim_name: String):
	if IdleFaceAnims.keys().any(func(anim: String): return anim_name.contains(anim)):
		parent_controller.face_blend = 0
	performing_event = false
