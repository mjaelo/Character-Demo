extends Node3D

func spawn_opponent():
	pass
	#var scene = load("res://mobs/mob/Mob.tscn")
	#for x in range(-5,5):
		#var mob:Mob = scene.instantiate()
		#mob.transform.origin += Vector3(x*3,0,5)
		#var race = MobConstants.MobRaces.values().pick_random()
		#var type := MobConstants.MobTypes.Civilian
		#var gender:int = MobConstants.get_random_gender.call()
		#MobGenerator.set_mob_data_to_mob(
			#MobGenerator.get_random_mob_data(mob.get_node("body/Armature/Skeleton3D"),race,type),
			#mob
		#)
		#add_child(mob)


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is Player:
		print("\n\nResetting Game\n\n")
		get_tree().reload_current_scene()
