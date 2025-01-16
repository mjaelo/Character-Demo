extends Node3D

func spawn_opponent():
	var mob = load("res://mobs/mob/Mob.tscn").instantiate()
	mob.transform.origin += Vector3(5,0,5)
	mob.scale /=2
	add_child(mob)
