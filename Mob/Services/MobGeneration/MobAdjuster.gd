extends Resource
class_name MobAdjuster

# === ADJUST (keep valid, re-randomize invalid) ===
static func adjust_body_data(skeleton:Skeleton3D, norms:Array[NormData], body_data:BodyData) -> BodyData:
	var mesh_data_names := BodyData.FIELD_NAMES
	var mesh_names := MobConstants.body_mesh_info.keys()
	for i in mesh_data_names.size():
		var mesh_name: String = mesh_names[i]
		var mesh_data_name: String = mesh_data_names[i]
		var mesh_info: MobMeshInfo = MobConstants.body_mesh_info[mesh_name]
		var mesh_instance := MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names: Array[String] = MobGetter._get_shape_names(mesh_name, mesh_instance)
		body_data[mesh_data_name] = adjust_mesh_data(mesh_name, shape_names, mesh_info, norms, body_data[mesh_data_name])
	
	# Propagate hair color to hair-linked meshes (Brows, Beard)TODO duplicated by TabBuilder MobGetter and MobAdjuster
	if body_data.hair_mesh && body_data.hair_mesh.has_color():
		var hair_color := body_data.hair_mesh.mesh_color
		for linked_name in MobConstants.hair_linked_names:
			var field := MobGetter._mesh_name_to_field(linked_name)
			if field && body_data.get(field):
				body_data[field].mesh_color = hair_color
	
	return body_data

static func adjust_equipment_data(skeleton:Skeleton3D, norms:Array[NormData], eq_data:EquipmentData) -> EquipmentData:
	var mesh_data_names := EquipmentData.FIELD_NAMES
	var mesh_names := MobConstants.eq_mesh_info.keys()
	for i in mesh_data_names.size():
		var mesh_name: String = mesh_names[i]
		var mesh_data_name: String = mesh_data_names[i]
		var mesh_info: MobMeshInfo = MobConstants.eq_mesh_info[mesh_name]
		var mesh_instance: MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names: Array[String] = MobGetter._get_shape_names(mesh_name, mesh_instance)
		eq_data[mesh_data_name] = adjust_mesh_data(mesh_name, shape_names, mesh_info, norms, eq_data[mesh_data_name])
	return eq_data

static func adjust_mesh_data(mesh_name:String, shape_names:Array[String], mesh_info:MobMeshInfo, norms:Array[NormData], mesh_data:MeshData) -> MeshData:
	mesh_data.mesh_file = adjust_mesh_file(mesh_name, mesh_data.mesh_file, norms, mesh_info.file_folder)
	mesh_data.mesh_color = adjust_mesh_color(mesh_name, mesh_data.mesh_color, norms, mesh_info.colors)
	mesh_data.mesh_shape = adjust_mesh_shape(mesh_name, mesh_data.mesh_shape, norms, mesh_info.shapes, shape_names)
	return mesh_data

# === ADJUST helpers (keep if valid, randomize if not) ===

static func adjust_mesh_file(mesh_name:String, mesh_file:String, norms:Array[NormData], file_folder:String) -> String:
	if !file_folder:
		return ""
	var all_tags := FileUtils.load_json_from_file(file_folder + "tag_info.json")
	var selected_tags: Array = all_tags[mesh_file] if all_tags.has(mesh_file) else []
	var tag_norms := norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Tag)
	var mesh_norms := norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Mesh)
	if is_mesh_file_within_norms(mesh_file, mesh_name, selected_tags, tag_norms, mesh_norms):
		return mesh_file
	var all_files := MobGetter._get_all_file_names(mesh_name, file_folder)
	if randf() <= MobConstants.variation_chance:
		tag_norms = tag_norms.filter(func(n): return n.enforce)
		mesh_norms = mesh_norms.filter(func(n): return n.enforce)
	return MobGetter._pick_valid_mesh_file(all_files, all_tags, mesh_name, tag_norms, mesh_norms)

static func adjust_mesh_color(mesh_name:String, mesh_color:Color, norms:Array[NormData], all_colors:Array[Color]) -> Color:
	if all_colors.is_empty():
		return Color.BLACK
	var color_norms := norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Color)
	if is_mesh_color_within_norms(mesh_color, mesh_name, color_norms):
		return mesh_color
	if randf() <= MobConstants.variation_chance:
		color_norms = color_norms.filter(func(n): return n.enforce)
	return MobGetter._pick_valid_mesh_color(all_colors, mesh_name, color_norms)

static func adjust_mesh_shape(mesh_name:String, mesh_shape:Array, norms:Array[NormData], shapes:Dictionary, shape_names:Array[String]) -> Array:
	if shapes.is_empty() || shape_names.size() != shapes.size():
		if !shapes.is_empty():
			print(mesh_name, " has undeclared shape keys. ", shape_names, " != ", shapes.keys())
		return mesh_shape
	var shape_norms := norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Shape)
	var shape_array := []
	for shape_id: int in shape_names.size():
		var shape_value = mesh_shape[shape_id] if mesh_shape && shape_id < mesh_shape.size() else null
		if shape_value != null && is_mesh_shape_within_norms(shape_value, mesh_name, shape_id, shape_norms):
			shape_array.append(shape_value)
		else:
			var shape_range: Array[float] = shapes[shape_names[shape_id]]
			var active_norms := shape_norms
			if randf() <= MobConstants.variation_chance:
				active_norms = shape_norms.filter(func(n): return n.enforce)
			shape_array.append(MobGetter._pick_valid_mesh_shape(shape_range, shape_id, mesh_name, active_norms))
	return shape_array

# === VALIDATION ===
static func is_mesh_file_within_norms(mesh_file: String, mesh_name:String, tags:Array, tag_norms: Array[NormData], mesh_norms: Array[NormData]) -> bool:
	if !mesh_file:
		return false
	for norm: NormData in tag_norms:
		if !norm.forbidden && !tags.has(norm.value):
			return false
		if norm.forbidden && tags.has(norm.value):
			return false
	for norm: NormData in mesh_norms:
		if !norm.value.has(mesh_name):
			continue
		var has_value: bool = norm.value[mesh_name] == mesh_file
		if !norm.forbidden && !has_value:
			return false
		if norm.forbidden && has_value:
			return false
	return true

static func is_mesh_color_within_norms(color: Color, mesh_name:String, color_norms: Array[NormData]) -> bool:
	if !color || color == Color(-1, -1, -1):
		return false
	for norm: NormData in color_norms:
		if !norm.value.has(mesh_name):
			continue
		var has_value: bool = norm.value[mesh_name].has(color)
		if !norm.forbidden && !has_value:
			return false
		if norm.forbidden && has_value:
			return false
	return true

static func is_mesh_shape_within_norms(shape_value: float, mesh_name:String, shape_id:int, shape_norms: Array[NormData]) -> bool:
	for norm: NormData in shape_norms:
		if !norm.value.has(mesh_name) || !norm.value[mesh_name].has(shape_id):
			continue
		var has_value: bool = norm.value[mesh_name][shape_id].has(shape_value)
		if !norm.forbidden && !has_value:
			return false
		if norm.forbidden && has_value:
			return false
	return true

# === ADJUST MOB TO RACE ===
static func adjust_mob_to_race(mob:Mob, race:int):
	var dict: Dictionary = MobConstants.race_action_dict[race]
	var skeleton = mob.get_node("body/Armature/Skeleton3D")
	var show_monster_body: bool = dict.has("show_monster_body") && dict.show_monster_body
	skeleton.get_node("monster-body").visible = show_monster_body
	var body_meshes := ["Eyelashes","Brows","Eyes"]
	body_meshes.append_array(MobConstants.meshes_with_skin)
	for child in skeleton.get_children():
		if body_meshes.has(child.name):
			child.visible = !show_monster_body
	mob.scale = Vector3.ONE if !dict.has("scale") else Vector3.ONE * dict.scale
	var body_mesh: MeshInstance3D = skeleton.get_node("Top")
	var material: StandardMaterial3D = body_mesh.get_active_material(0)
	material.albedo_texture_msdf = [MobConstants.MobRaces.Statue, MobConstants.MobRaces.Spirit].has(race)
	var def_body_colors := {"Eyes": {0: Color.WHITE, 2: Color.BLACK}, "Eyelashes": {0: Color.BLACK}}
	def_body_colors.Eyes[0] = Color.WHITE if !dict.has("eye_whites") else dict.eye_whites
	def_body_colors.Eyes[2] = Color.BLACK if !dict.has("eye_pupil") else dict.eye_pupil
	for mesh_name in def_body_colors.keys():
		for mat_nr in def_body_colors[mesh_name].keys():
			var color = def_body_colors[mesh_name][mat_nr] if race != MobConstants.MobRaces.Statue else MobConstants.Color_Statue_Grey
			MobUtils.set_mesh_color(color, skeleton.get_node(mesh_name), mat_nr)
