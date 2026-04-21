extends Node3D

@onready var creator: Creator = $Creator
@onready var mob := $Player/Mob
@onready var skeleton := $Player/Mob/body/Armature/Skeleton3D

func _ready() -> void:
	creator.initialize(mob, skeleton)
