extends Node

var is_enforce_mesh_name := func (norms:MeshNormData, mesh_name:String): 
	return norms.enforce.has("mesh_name") && norms.enforce.mesh_name.has(mesh_name)
var is_enforce_color := func (norms:MeshNormData, mesh_name:String): 
	return norms.enforce.has("color") && norms.enforce.color.has(mesh_name)
var is_enforce_shape := func (norms:MeshNormData, mesh_name:String, shape_id:int): 
	return norms.enforce.has("shape") && norms.enforce.shape.has(mesh_name) && norms.enforce.shape[mesh_name].has(shape_id)

# GET
# get random body and eq data and adjust to race
func get_random_mob_data(skeleton:Skeleton3D, race:=-1, type:=-1, gender:=-1, mob_name:="empty", mob_data := MobData.new(race,type,"",gender))-> MobData:	
	# pick random race, type and gender if not given TODO add rarity?
	var possible_values := {
		"race": MobConstants.MobRaces.values(),
		"type": MobConstants.MobTypes.values(),
		"gender": [MobConstants.Gender.Male,MobConstants.Gender.Female]}
	for v_name in possible_values.keys():
		var v_vals = possible_values[v_name]
		if mob_data[v_name] < 0:
			mob_data[v_name] = v_vals.pick_random()
			if v_name == "gender" && randf() < MobConstants.variation_chance:
				mob_data[v_name] = MobConstants.Gender.NonBin
	
	# get random body and eq
	mob_data.body_data = get_random_body(skeleton, 
		mob_data.gender, mob_data.type, mob_data.race,
		mob_data.body_data)
	mob_data.equipment_data = get_random_equipment(skeleton,
		mob_data.gender, mob_data.type, mob_data.race, 
		mob_data.equipment_data)
	
	mob_data.mob_name = mob_name if mob_name != "empty" else MobConstants.mob_names[mob_data.gender].pick_random()
	return mob_data

# get random body or adjust existing
func get_random_body(skeleton:Skeleton3D, gender:=MobConstants.Gender.NonBin, type := MobConstants.MobTypes.Civilian, race := MobConstants.MobRaces.Human, body_data := BodyData.new())-> BodyData:
	var mesh_data_names := Utils.get_user_defined_variables(body_data)
	var mesh_names := MobConstants.body_mesh_info.keys()
	
	var rtg_norms := [MobConstants.race_norms[race], MobConstants.type_norms[type], MobConstants.gender_norms[gender]]
	var bulk_mesh := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_mesh.has("BodyBulk"))
	var bulk_color := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_colors.has("BodyBulk"))
	
	for i in mesh_data_names.size():
		# gather variables 
		var mesh_name:String = mesh_names[i]
		var mesh_data_name:String = mesh_data_names[i]
		var mesh_info:Dictionary = MobConstants.body_mesh_info[mesh_name]
		var mesh_instance:MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names := []
		if MobConstants.shape_control_meshes.has(mesh_name):
			shape_names = MobUtils.get_shape_names_from_mesh(mesh_instance)
		
		# get random data
		var mesh_data := get_random_mesh_data(mesh_name, shape_names, mesh_info, 
			gender, type, race, body_data[mesh_data_name])
		
		# link hair color
		if MobConstants.hair_linked_names.has(mesh_name):
			mesh_data.mesh_color = body_data.hair_mesh.mesh_color
		
		# bulk changes
		mesh_data.mesh_name = mesh_data.mesh_name if !bulk_mesh else bulk_mesh[0].mandatory_mesh["BodyBulk"]
		mesh_data.mesh_color = mesh_data.mesh_color if !bulk_color else bulk_color[0].mandatory_colors["BodyBulk"]
		
		body_data[mesh_data_name] = mesh_data
	
	return body_data

# get random body or adjust existing
func get_random_equipment(skeleton:Skeleton3D, gender:=MobConstants.Gender.NonBin, type := MobConstants.MobTypes.Civilian, race := MobConstants.MobRaces.Human, eq_data := EquipmentData.new())-> EquipmentData:
	var mesh_data_names := Utils.get_user_defined_variables(eq_data)
	var mesh_names := MobConstants.eq_mesh_info.keys()
	
	var rtg_norms := [MobConstants.race_norms[race], MobConstants.type_norms[type], MobConstants.gender_norms[gender]]
	var bulk_mesh := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_mesh.has("EquipmentBulk"))
	var bulk_color := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_colors.has("EquipmentBulk"))
	
	for i in mesh_data_names.size():
		# gather variables 
		var mesh_name:String = mesh_names[i]
		var mesh_data_name:String = mesh_data_names[i]
		var mesh_data: MeshData
		var mesh_info:Dictionary = MobConstants.eq_mesh_info[mesh_name]
		var mesh_instance:MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names := []
		if MobConstants.shape_control_meshes.has(mesh_name):
			shape_names = MobUtils.get_shape_names_from_mesh(mesh_instance)
		
		# get random data
		mesh_data = get_random_mesh_data(mesh_name, shape_names, mesh_info, 
			gender, type, race, eq_data[mesh_data_name])
		
		# bulk changes
		mesh_data.mesh_name = mesh_data.mesh_name if !bulk_mesh else bulk_mesh[0].mandatory_mesh["EquipmentBulk"]
		mesh_data.mesh_color = mesh_data.mesh_color if !bulk_color else bulk_color[0].mandatory_colors["EquipmentBulk"]
		
		eq_data[mesh_data_name] = mesh_data
		
	return eq_data

# get random body or adjust existing
func get_random_mesh_data(mesh_name:String, shape_names:Array, mesh_info:Dictionary, 
		gender:= MobConstants.Gender.NonBin, mob_type := MobConstants.MobTypes.Civilian, race := MobConstants.MobRaces.Human, 
		mesh_data := MeshData.new()) -> MeshData:
	
	var rtg_norms := [MobConstants.race_norms[race], MobConstants.type_norms[mob_type], MobConstants.gender_norms[gender]]
	
	# mesh
	if mesh_name == "Body":
		pass
	mesh_info.mesh_folder = "" if !mesh_info.has("mesh_folder") else mesh_info.mesh_folder
	var all_tags := Utils.read_json_file(mesh_info.mesh_folder+"tag_info.json")
	var selected_tags:Array = all_tags[mesh_data.mesh_name] if all_tags.has(mesh_data.mesh_name) else []
	if !is_mesh_name_within_norms(mesh_data.mesh_name, mesh_name, selected_tags, rtg_norms):
		# get possible meshes
		var all_files: Array
		if MobConstants.half_empty_names.has(mesh_name) && randf()>.5 : # 50% for empty option
			all_files = ["empty"]
		else:
			all_files = Utils.get_file_names(mesh_info.mesh_folder) if mesh_info.mesh_folder else [""]
			# add empty option
			if !MobConstants.non_empty_names.has(mesh_name) && mesh_info.mesh_folder:# && !(mesh_name == "Hair" && gender == MobConstants.Gender.Female && randf() > MobConstants.variation_chance): # protection against bald femals
				all_files.insert(0,"empty") # add option to hide mesh
		
		# get random mesh from all_files based on norms
		mesh_data.mesh_name = get_random_mesh_name(all_files, mesh_name, all_tags, rtg_norms)
	
	# color					beard and brow color variations are disabled in get_random_body
	if mesh_info.has("color_range") && !MobConstants.hair_linked_names.has(mesh_name):
		if !is_mesh_color_within_norms(mesh_data.mesh_color, mesh_name, rtg_norms):
			# transform float min max values to floar range between min max
			var color_range =  mesh_info.color_range.values().map(
				func (minmax:Array): return range(minmax[0]*100, minmax[1]*100).map(
					func (e): return e/100.0))
			mesh_data.mesh_color = get_random_mesh_color(color_range, mesh_name, rtg_norms)
	
	# shape keys
	var shape_array := []
	for shape_id in shape_names.size():
		var shape_value = mesh_data.mesh_shape[shape_id] if mesh_data.mesh_shape else null
		if !shape_value || !is_mesh_shape_within_norms(shape_value, mesh_name, shape_id, rtg_norms):
			var shape_name = shape_names[shape_id]
			var min_r = mesh_info.shape_limits[shape_name][0] if mesh_info.has("shape_limits") else 0
			var max_r = mesh_info.shape_limits[shape_name][1] if mesh_info.has("shape_limits") else 1
			var shape_range = range(min_r*10, max_r*10+1).map(func (ele): return ele/10.0)
			shape_value = get_random_mesh_shape(shape_range, shape_id, mesh_name, rtg_norms)
		
		# set shape value in array corresponding to shape order in mesh
		shape_array.append(shape_value)
	mesh_data.mesh_shape = shape_array
	
	return mesh_data

# NEW GET
# get random valid mesh name
func get_random_mesh_name(all_files:Array, mesh_name:String, all_tags:Dictionary, rtg_norms: Array) -> String:
	if randf() > MobConstants.variation_chance || rtg_norms.any(func (norms): return is_enforce_mesh_name.call(norms, mesh_name)):
		for norms:MeshNormData in rtg_norms:
			# check forbidden, mandatory tags
			if norms.mandatory_tags:
				var mandatory_files = all_files.filter(func (file_name): 
					return all_tags.has(file_name) && Utils.has_all(
						all_tags[file_name],norms.mandatory_tags))
				all_files = mandatory_files if mandatory_files else all_files
			if norms.forbidden_tags:
				var forbidden_files = all_files.filter(func (file_name): 
					return !all_tags.has(file_name) || !Utils.has_any(
						all_tags[file_name],norms.forbidden_tags))
				all_files = forbidden_files if forbidden_files else all_files
			
			# check forbidden, mandatory meshes
			if norms.mandatory_mesh && norms.mandatory_mesh.has(mesh_name):
				var mandatory_files = all_files.filter(func (file_name): 
					return [norms.mandatory_mesh[mesh_name]].has(file_name))
				all_files = mandatory_files if mandatory_files else [norms.mandatory_mesh[mesh_name]]
			if norms.forbidden_mesh && norms.forbidden_mesh.has(mesh_name):
				var forbidden_files = all_files.filter(func (file_name): 
					return ![norms.forbidden_mesh[mesh_name]].has(file_name))
				all_files = forbidden_files if forbidden_files else all_files
	
	if !all_files:
		print("ERROR")
		return "empty"
	return all_files.pick_random()

# get random valid color
func get_random_mesh_color(mesh_color_range:Array, mesh_name:String, rtg_norms: Array) -> Color:
	for norms:MeshNormData in rtg_norms:
		if norms.mandatory_colors && norms.mandatory_colors.has(mesh_name):
			var color = norms.mandatory_colors[mesh_name]
			mesh_color_range = [[color.h],[color.s],[color.v],[color.a]] if color is Color else color
		elif norms.forbidden_colors:
			mesh_color_range = mesh_color_range.filter(func (color): 
				return !norms.forbidden_colors.has(color)
			)
	
	if !mesh_color_range:
		print("ERROR")
		return Color(0,0,0)
	# pick random hue, saturation, brightness from ranges
	return Color.from_hsv(
			mesh_color_range[0].pick_random(),
			mesh_color_range[1].pick_random(),
			mesh_color_range[2].pick_random(),
			1 if mesh_color_range.size()<4 else mesh_color_range[3].pick_random()
		)

# get random valid mesh shape
func get_random_mesh_shape(shape_range:Array, shape_id:int, mesh_name:String, rtg_norms: Array) -> float:
	if randf() > MobConstants.variation_chance || rtg_norms.any(func (norms): return is_enforce_shape.call(norms, mesh_name,shape_id)):
		for norms:MeshNormData in rtg_norms:
			if norms.mandatory_shapes.has(mesh_name) && norms.mandatory_shapes[mesh_name].has(shape_id):
				shape_range = [norms.mandatory_shapes[mesh_name][shape_id]]
			elif norms.forbidden_shapes.has(mesh_name):
				shape_range = shape_range.filter(func (shape_value): return !norms.forbidden_shapes[mesh_name].has(shape_value))
	
	if !shape_range:
		print("ERROR")
		return 0
	return shape_range.pick_random()

# CHECK
# check validity of mesh_file_name
func is_mesh_name_within_norms(mesh_file_name: String, mesh_name:String, tags:Array, rtg_norms: Array) -> bool:
	if !mesh_file_name:
		return false
	
	for norms:MeshNormData in rtg_norms:
		if mesh_name == "Brows":
			pass
		# check tags
		if norms.mandatory_tags:
			return true if Utils.has_all(tags, norms.mandatory_tags) else false
		if norms.forbidden_tags && Utils.has_any(tags, norms.forbidden_tags):
			return false
		# check tags
		if norms.mandatory_mesh.has(mesh_name):
			return true if norms.mandatory_mesh[mesh_name].has(mesh_file_name) else false
		if norms.forbidden_mesh.has(mesh_name) && norms.forbidden_mesh[mesh_name].has(mesh_file_name):
			return false
	return true

# check validity of color
func is_mesh_color_within_norms(color: Color, mesh_name:String, rtg_norms: Array) -> bool:
	if color == Color(-1,-1,-1,1):
		return false
	
	for norms:MeshNormData in rtg_norms:
		# check colors
		if norms.mandatory_colors.has(mesh_name):
			return true if norms.mandatory_colors[mesh_name].has(color) else false
		if norms.forbidden_colors.has(mesh_name) && norms.forbidden_colors[mesh_name].has(color):
			return false
	return true

# check validity of shape_value
func is_mesh_shape_within_norms(shape_value: float, mesh_name:String, shape_id:int, rtg_norms: Array) -> bool:
	for norms:MeshNormData in rtg_norms:
		# check shapes
		if norms.mandatory_shapes.has(mesh_name) && norms.mandatory_shapes[mesh_name].has(shape_id):
			return true if [norms.mandatory_shapes[mesh_name][shape_id]].has(shape_value) else false
		if norms.forbidden_shapes.has(mesh_name) && norms.forbidden_shapes[mesh_name].has(shape_id) && norms.forbidden_shapes[shape_id].has(shape_value):
			return false
	return true

# SET
func set_mob_data_to_mob(mob_data:MobData, mob:Mob):
	mob.mob_name = mob_data.mob_name
	mob.race = mob_data.race
	mob.type = mob_data.type
	mob.gender = mob_data.gender
	mob.equipment_data = mob_data.equipment_data
	mob.body_data = mob_data.body_data
	mob.adjust_mob_to_race(mob_data.race)
	set_equipment_data(mob_data.equipment_data, mob)
	set_body_data(mob_data.body_data, mob)

func set_body_data(body_data:BodyData, mob:Mob):
	mob.body_data = body_data
	var skeleton:Skeleton3D = mob.get_node("body/Armature/Skeleton3D")
	var mesh_names:Array = MobConstants.body_mesh_info.keys()
	var mesh_data_names := Utils.get_user_defined_variables(body_data)
	
	for i in mesh_data_names.size():
		var mesh_name:String = mesh_names[i]
		var mesh_data:MeshData = body_data[mesh_data_names[i]]
		var mesh_instance:MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		set_mesh_data(mesh_data, mesh_name, mesh_instance)

func set_equipment_data(eq_data:EquipmentData, mob:Mob):
	mob.equipment_data = eq_data
	var skeleton:Skeleton3D = mob.get_node("body/Armature/Skeleton3D")
	var mesh_names:Array = MobConstants.eq_mesh_info.keys()
	var mesh_datas := Utils.get_user_defined_variables(eq_data)
	var is_hair_bald := false
	
	for i in mesh_datas.size():
		var mesh_name:String = mesh_names[i]
		var mesh_data:MeshData = eq_data[mesh_datas[i]]
		var mesh_instance:MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		if mesh_instance.name == "Hat":
			var hair_data:MeshData = mob.body_data.hair_mesh
			is_hair_bald = hair_data.mesh_name == "empty"
		set_mesh_data(mesh_data, mesh_name, mesh_instance, is_hair_bald)

func set_mesh_data(mesh_data:MeshData, mesh_name:String,mesh_instance:MeshInstance3D, is_hair_bald := false):
	# mesh
	if mesh_data.mesh_name:
		var is_body_mesh := MobConstants.body_mesh_info.has(mesh_name)
		var path := "" 
		if mesh_data.mesh_name != "empty":
			if is_body_mesh:
				path = MobConstants.body_mesh_info[mesh_name].mesh_folder
			else:
				path = MobConstants.eq_mesh_info[mesh_name].mesh_folder 
		MobUtils.set_mesh(mesh_data.mesh_name,mesh_instance,path, is_hair_bald)
	
	# color
	if mesh_data.mesh_color != Color(-1,-1,-1):
		MobUtils.set_mesh_color(mesh_data.mesh_color, mesh_instance)
	
	# shape keys
	if mesh_data.mesh_shape:
		var shape_names = MobUtils.get_shape_names_from_mesh(mesh_instance)
		if mesh_data.mesh_shape.size() != shape_names.size():
			print(mesh_name+" shapes differ in saved data and mesh")
			return
		
		for i in mesh_data.mesh_shape.size():
			var value = mesh_data.mesh_shape[i]
			var shape_name = shape_names[i]
			MobUtils.set_skeleton_shape_key(value,shape_name,mesh_instance.get_parent())
