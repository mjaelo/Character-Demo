extends Node3D

func spawn_opponent():
	var scene = load("res://mobs/mob/Mob.tscn")
	for x in range(-5,5):
		var mob:Mob = scene.instantiate()
		mob.transform.origin += Vector3(x*3,0,5)
		var race:int = MobConstants.MobRaces.values().pick_random()
		var type:int = MobConstants.MobTypes.Civilian
		BodyGenerator.set_mob_data_to_mob(
			BodyGenerator.get_random_mob_data(mob.get_node("body/Armature/Skeleton3D"),race,type),
			mob
		)
		add_child(mob)
