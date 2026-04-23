extends Resource
class_name MobGetter

# TODO when changing clothes, colors reset

# GET
# get random body and eq data and adjust to race
static func get_random_mob_data(skeleton:Skeleton3D, race:=-1, type:=-1, gender:=-1, mob_name:="empty", mob_data := MobData.new(race,type,"",gender))-> MobData:	
	# pick random race, type and gender if not given
	var possible_values := {
		"race": MobConstants.MobRaces.values(),
		"type": MobConstants.MobTypes.values(),
		"gender": [MobConstants.Gender.Male,MobConstants.Gender.Female]}
	for v_name in possible_values.keys():
		var v_vals = possible_values[v_name]
		if mob_data[v_name] < 0:
			mob_data[v_name] = v_vals.pick_random()
			if v_name == "gender":
				mob_data[v_name] = MobConstants.get_random_gender.call()
	
	var rtg_norms := _get_rtg_norms(mob_data.race, mob_data.type, mob_data.gender)
	mob_data.body_data = get_random_body_data(skeleton, rtg_norms, mob_data.body_data)
	mob_data.equipment_data = get_random_equipment_data(skeleton, rtg_norms, mob_data.equipment_data)
	
	mob_data.mob_name = mob_name if mob_name != "empty" else MobConstants.mob_names[mob_data.gender].pick_random()
	return mob_data

# NORMS HELPER
static func _get_rtg_norms(race: int, type: int, gender: int) -> Array[NormData]:
	var rtg_norms: Array[NormData] = []
	rtg_norms.append_array(MobConstants.race_norms[race])
	rtg_norms.append_array(MobConstants.type_norms[type])
	rtg_norms.append_array(MobConstants.gender_norms[gender])
	return rtg_norms

# === RANDOM (fresh) ===

static func get_random_body_data(skeleton:Skeleton3D, rtg_norms:Array[NormData], body_data := BodyData.new()) -> BodyData:
	var mesh_data_names := BodyData.FIELD_NAMES
	var mesh_names := MobConstants.body_mesh_info.keys()
	for i in mesh_data_names.size():
		var mesh_name: String = mesh_names[i]
		var mesh_data_name: String = mesh_data_names[i]
		var mesh_info: MobMeshInfo = MobConstants.body_mesh_info[mesh_name]
		var mesh_instance := MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names: Array[String] = _get_shape_names(mesh_name, mesh_instance)
		body_data[mesh_data_name] = get_random_mesh_data(mesh_name, shape_names, mesh_info, rtg_norms)
	
	# Propagate hair color to hair-linked meshes (Brows, Beard)TODO duplicated by TabBuilder MobGetter and MobAdjuster
	if body_data.hair_mesh && body_data.hair_mesh.has_color():
		var hair_color := body_data.hair_mesh.mesh_color
		for linked_name in MobConstants.hair_linked_names:
			var field := _mesh_name_to_field(linked_name)
			if field && body_data.get(field):
				body_data[field].mesh_color = hair_color
	
	return body_data

static func get_random_equipment_data(skeleton:Skeleton3D, rtg_norms:Array[NormData], eq_data := EquipmentData.new()) -> EquipmentData:
	var mesh_data_names := EquipmentData.FIELD_NAMES
	var mesh_names := MobConstants.eq_mesh_info.keys()
	for i in mesh_data_names.size():
		var mesh_name: String = mesh_names[i]
		var mesh_data_name: String = mesh_data_names[i]
		var mesh_info: MobMeshInfo = MobConstants.eq_mesh_info[mesh_name]
		var mesh_instance: MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names: Array[String] = _get_shape_names(mesh_name, mesh_instance)
		eq_data[mesh_data_name] = get_random_mesh_data(mesh_name, shape_names, mesh_info, rtg_norms)
	return eq_data

static func get_random_mesh_data(mesh_name:String, shape_names:Array[String], mesh_info:MobMeshInfo, rtg_norms:Array[NormData]) -> MeshData:
	var mesh_data := MeshData.new()
	mesh_data.mesh_file = get_random_mesh_file(mesh_name, rtg_norms, mesh_info.file_folder)
	mesh_data.mesh_color = get_random_mesh_color(mesh_name, rtg_norms, mesh_info.colors)
	mesh_data.mesh_shape = get_random_mesh_shape(mesh_name, rtg_norms, mesh_info.shapes, shape_names)
	return mesh_data

static func get_random_mesh_file(mesh_name:String, rtg_norms:Array[NormData], file_folder:String) -> String:
	if !file_folder:
		return ""
	var all_tags := FileUtils.load_json_from_file(file_folder + "tag_info.json")
	var tag_norms := rtg_norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Tag)
	var mesh_norms := rtg_norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Mesh)
	var all_files := _get_all_file_names(mesh_name, file_folder)
	if !all_files:
		print("No files found for mesh ", mesh_name)
		return "empty"
	# enforce_only: only apply enforced norms when variation chance triggers
	if randf() <= MobConstants.variation_chance:
		tag_norms = tag_norms.filter(func(n): return n.enforce)
		mesh_norms = mesh_norms.filter(func(n): return n.enforce)
	return _pick_valid_mesh_file(all_files, all_tags, mesh_name, tag_norms, mesh_norms)

static func get_random_mesh_color(mesh_name:String, rtg_norms:Array[NormData], all_colors:Array[Color]) -> Color:
	if all_colors.is_empty():
		return Color.BLACK
	var color_norms := rtg_norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Color)
	if randf() <= MobConstants.variation_chance:
		color_norms = color_norms.filter(func(n): return n.enforce)
	return _pick_valid_mesh_color(all_colors, mesh_name, color_norms)

static func get_random_mesh_shape(mesh_name:String, rtg_norms:Array[NormData], shapes:Dictionary, shape_names:Array[String]) -> Array:
	if shapes.is_empty() || shape_names.size() != shapes.size():
		if !shapes.is_empty():
			print(mesh_name, " has undeclared shape keys. ", shape_names, " != ", shapes.keys())
		return []
	var shape_norms := rtg_norms.filter(func(n: NormData): return n.type == MobConstants.NormType.Shape)
	var shape_array := []
	for shape_id: int in shape_names.size():
		var shape_range: Array[float] = shapes[shape_names[shape_id]]
		if !shape_range:
			print(mesh_name, " shape ", shape_names[shape_id], " has no range declared")
			shape_array.append(0.0)
			continue
		var active_norms := shape_norms
		if randf() <= MobConstants.variation_chance:
			active_norms = shape_norms.filter(func(n): return n.enforce)
		shape_array.append(_pick_valid_mesh_shape(shape_range, shape_id, mesh_name, active_norms))
	return shape_array

# === INTERNAL HELPERS ===
const _NAME_TO_FIELD := { #TODO not needed
	"Body": "body_mesh", "Head": "head_mesh", "Eyes": "eye_mesh",
	"Eyelashes": "lashes_mesh", "Hair": "hair_mesh", "Beard": "beard_mesh", "Brows": "brow_mesh",
	"Top": "top_mesh", "Bottom": "bottom_mesh", "Shoes": "shoe_mesh",
	"Hat": "hat_mesh", "Right Hand": "r_hand_mesh", "Left Hand": "l_hand_mesh", "Accessory": "accessory_mesh"
}

static func _mesh_name_to_field(mesh_name: String) -> String:
	return _NAME_TO_FIELD[mesh_name] if _NAME_TO_FIELD.has(mesh_name) else ""

static func _get_shape_names(mesh_name: String, mesh_instance: MeshInstance3D) -> Array[String]:
	var shape_names: Array[String] = []
	if MobConstants.meshes_with_shapes.has(mesh_name) && mesh_instance:
		shape_names.append_array(MobUtils.get_shape_names_from_mesh(mesh_instance.mesh))
	return shape_names

static func _get_all_file_names(mesh_name:String, file_folder:String) -> Array[String]:
	var all_files: Array[String]
	if MobConstants.half_empty_names.has(mesh_name) && randf() > .5:
		all_files = ["empty"]
	else:
		all_files.append_array(FileUtils.get_file_names(file_folder) if file_folder else [])
		if !MobConstants.non_empty_names.has(mesh_name) && file_folder:
			all_files.insert(0, "empty")
	return all_files

static func _pick_valid_mesh_file(all_files:Array, all_tags:Dictionary, mesh_name:String, tag_norms: Array[NormData], mesh_norms: Array[NormData]) -> String:
	var possible_files := all_files.duplicate()
	
	# Apply norms one-by-one (they arrive ordered: race→type→gender)
	# Skip any norm that would eliminate all options
	for norm: NormData in tag_norms:
		var filtered := possible_files.filter(func(file_name: String):
			var file_tags: Array = all_tags[file_name] if all_tags.has(file_name) else []
			if norm.forbidden:
				return !(file_tags && GeneralUtils.has_any(file_tags, norm.value))
			else:
				return file_tags && GeneralUtils.has_all(file_tags, norm.value)
		)
		if filtered:
			possible_files = filtered
	
	for norm: NormData in mesh_norms:
		if !norm.value.has(mesh_name):
			continue
		var filtered := possible_files.filter(func(file_name: String):
			var matches: bool = norm.value[mesh_name] == file_name
			return !matches if norm.forbidden else matches
		)
		if filtered:
			possible_files = filtered
	
	return possible_files.pick_random()

static func _pick_valid_mesh_color(all_colors:Array[Color], mesh_name:String, color_norms: Array[NormData]) -> Color:
	var possible_colors: Array = all_colors.duplicate()
	
	for norm: NormData in color_norms:
		if !norm.value.has(mesh_name):
			continue
		var filtered := possible_colors.filter(func(color: Color):
			var matches: bool = norm.value[mesh_name].has(color)
			return !matches if norm.forbidden else matches
		)
		if filtered:
			possible_colors = filtered
	
	return possible_colors.pick_random()

static func _pick_valid_mesh_shape(all_shape_values:Array, shape_id:int, mesh_name:String, shape_norms: Array[NormData]) -> float:
	var possible: Array = all_shape_values.duplicate()
	
	for norm: NormData in shape_norms:
		if !norm.value.has(mesh_name) || !norm.value[mesh_name].has(shape_id):
			continue
		var filtered := possible.filter(func(shape_val):
			var matches: bool = norm.value[mesh_name][shape_id].has(shape_val)
			return !matches if norm.forbidden else matches
		)
		if filtered:
			possible = filtered
	
	return possible.pick_random()
