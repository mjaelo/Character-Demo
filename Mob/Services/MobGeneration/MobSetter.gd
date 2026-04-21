extends Resource
class_name MobSetter

# === SET ===
static func set_mob_data_to_mob(mob_data:MobData, mob:Mob):
	mob.mob_name = mob_data.mob_name
	mob.race = mob_data.race
	mob.type = mob_data.type
	mob.gender = mob_data.gender
	mob.equipment_data = mob_data.equipment_data
	mob.body_data = mob_data.body_data
	MobAdjuster.adjust_mob_to_race(mob, mob_data.race)
	set_body_data(mob_data.body_data, mob)
	set_equipment_data(mob_data.equipment_data, mob)

static func set_body_data(body_data:BodyData, mob:Mob):
	mob.body_data = body_data
	var skeleton: Skeleton3D = mob.get_node("body/Armature/Skeleton3D")
	var mesh_names: Array = MobConstants.body_mesh_info.keys()
	var mesh_data_names := BodyData.FIELD_NAMES
	for i in mesh_data_names.size():
		var mesh_name: String = mesh_names[i]
		var mesh_data: MeshData = body_data[mesh_data_names[i]]
		var mesh_instance: MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		if mesh_instance:
			set_mesh_data(mesh_data, mesh_name, mesh_instance)

static func set_equipment_data(eq_data:EquipmentData, mob:Mob):
	mob.equipment_data = eq_data
	var skeleton: Skeleton3D = mob.get_node("body/Armature/Skeleton3D")
	var mesh_names: Array = MobConstants.eq_mesh_info.keys()
	var mesh_datas := EquipmentData.FIELD_NAMES
	for i in mesh_datas.size():
		var mesh_name: String = mesh_names[i]
		var mesh_data: MeshData = eq_data[mesh_datas[i]]
		var mesh_instance: MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		if mesh_instance:
			set_mesh_data(mesh_data, mesh_name, mesh_instance)

static func set_mesh_data(mesh_data:MeshData, mesh_name:String, mesh_instance:MeshInstance3D):
	if mesh_data.mesh_file:
		var is_body_mesh := MobConstants.body_mesh_info.has(mesh_name)
		var mesh_info: MobMeshInfo = MobConstants.body_mesh_info[mesh_name] if is_body_mesh else MobConstants.eq_mesh_info[mesh_name]
		if mesh_info.file_folder:
			MobUtils.set_mesh(mesh_data.mesh_file, mesh_instance, mesh_info.file_folder)
		elif mesh_data.mesh_file == "empty":
			mesh_instance.hide()
	if mesh_data.has_color():
		var material_nr = 0 if mesh_name == "Body" else -1
		MobUtils.set_mesh_color(mesh_data.mesh_color, mesh_instance, material_nr)
	if mesh_data.mesh_shape:
		var shape_names = MobUtils.get_shape_names_from_mesh(mesh_instance.mesh)
		if mesh_data.mesh_shape.size() != shape_names.size():
			print(mesh_name + " shapes differ in saved data and mesh")
			return
		for i in mesh_data.mesh_shape.size():
			var value: float = float(mesh_data.mesh_shape[i])
			var shape_name: String = shape_names[i]
			MobUtils.set_skeleton_shape_key(value, shape_name, mesh_instance.get_parent())
