extends Node3D

@onready var creator: Creator = $Creator
@onready var mob := $Player/Mob
@onready var skeleton := $Player/Mob/body/Armature/Skeleton3D

func _ready() -> void:
	creator.init(mob, skeleton)
	# take away player control
	creator.toggle_player_control(false)
