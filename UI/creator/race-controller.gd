extends Control


func race_changed(race:int,type:int,gender:int,skeleton:Skeleton3D):
	# Race Info
	var eq_data := BodyGenerator.get_random_equipment(skeleton,gender,type)
	var body_data := BodyGenerator.get_random_body(skeleton,gender)
	if race != MobConstants.MobRaces.Human:
		body_data = adjust_body_to_race(body_data,race)
		eq_data = adjust_eq_to_race(eq_data,race)
		adjust_skeleton_to_race(race, skeleton)
	
	$"../".set_body_data(body_data)
	$"../".set_equipment_data(eq_data)

func adjust_skeleton_to_race(race:int, skeleton:Skeleton3D):
	# skeleton
	var is_skeleton:bool = race == MobConstants.MobRaces.Skeleton
	for child in skeleton.get_children():
		child.visible = !is_skeleton
	skeleton.get_node("monster-body").visible = is_skeleton
	
	# spirit
	var is_spirit:bool = race == MobConstants.MobRaces.Spirit
	if is_spirit:
		skeleton.scale = Vector3.ONE * .75
	
	# ogre
	var is_ogre:bool = race == MobConstants.MobRaces.Ogre
	if is_ogre:
		skeleton.scale = Vector3.ONE*1.5
	
	if !is_ogre && !is_spirit:
		skeleton.scale = Vector3.ONE

func adjust_body_to_race(body_data:BodyData,race:int) -> BodyData:
	if race == MobConstants.MobRaces.Skeleton:
		body_data.body_mesh.mesh_name = "empty"
		body_data.hair_mesh.mesh_name = "empty"
		body_data.beard_mesh.mesh_name = "empty"
		body_data.lashes_mesh.mesh_name = "empty"
		body_data.eye_mesh.mesh_name = "empty"
	elif race == MobConstants.MobRaces.Ogre:
		body_data.body_mesh.mesh_color = Color.DARK_OLIVE_GREEN
		body_data.hair_mesh.mesh_name = "empty"
		body_data.beard_mesh.mesh_name = "empty"
		body_data.lashes_mesh.mesh_name = "empty"
		body_data.brow_mesh.mesh_name = "empty"
		body_data.body_mesh.mesh_shape[1] = 1
	elif race == MobConstants.MobRaces.Spirit:
		body_data.body_mesh.mesh_color = Color(100, 100, 0.2, 1.0)
		body_data.eye_mesh.mesh_color = Color(100, 100, 100, 1.0)
		body_data.hair_mesh.mesh_name = "empty"
	elif race == MobConstants.MobRaces.Demon:
		body_data.body_mesh.mesh_color = Color.DARK_RED
	elif race == MobConstants.MobRaces.Statue:
		body_data.eye_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		body_data.lashes_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		body_data.body_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		body_data.hair_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		body_data.brow_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		body_data.beard_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
	return body_data

func adjust_eq_to_race(eq_data:EquipmentData,race:int) -> EquipmentData:
	if race == MobConstants.MobRaces.Skeleton:
		eq_data.top_mesh.mesh_name = "empty"
	elif race == MobConstants.MobRaces.Ogre:
		eq_data.top_mesh.mesh_name = "empty"
		eq_data.hat_mesh.mesh_name = "empty"
	elif race == MobConstants.MobRaces.Spirit:
		eq_data.hat_mesh.mesh_name = "empty"
		eq_data.top_mesh.mesh_name = "empty"
		eq_data.bottom_mesh.mesh_name = "empty"
	elif race == MobConstants.MobRaces.Demon:
		eq_data.top_mesh.mesh_color = Color.DARK_RED
	elif race == MobConstants.MobRaces.Statue:
		eq_data.top_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		eq_data.bottom_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		eq_data.shoe_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
		eq_data.hat_mesh.mesh_color = Color(0.3, 0.3, 0.3, 0)
	return eq_data
