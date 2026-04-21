extends Node
# TODO when changing clothes, colors reset

var is_enforce_mesh_name := func (norms:MeshNormData, mesh_name:String): 
	return norms.enforce.has("mesh_name") && norms.enforce.mesh_name.has(mesh_name)
var is_enforce_tags := func (norms:MeshNormData, all_tags:Dictionary): 
	return norms.enforce.has("tags") && all_tags.values().any(func (val:Array): return GeneralUtils.has_any(val, norms.enforce.tags))
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
			if v_name == "gender":
				mob_data[v_name] = MobConstants.get_random_gender.call()
	
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
	var mesh_data_names := BodyData.FIELD_NAMES
	var mesh_names := MobConstants.body_mesh_info.keys()
	
	var rtg_norms := [MobConstants.race_norms[race], MobConstants.type_norms[type], MobConstants.gender_norms[gender]]
	var bulk_mesh := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_mesh.has("BodyBulk"))
	var bulk_color := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_colors.has("BodyBulk"))
	
	for i in mesh_data_names.size():
		# gather variables 
		var mesh_name:String = mesh_names[i]
		var mesh_data_name:String = mesh_data_names[i]
		var mesh_info:MobMeshInfo = MobConstants.body_mesh_info[mesh_name]
		var mesh_instance := MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names := []
		
		if MobConstants.shape_control_meshes.has(mesh_name) && mesh_instance:
			shape_names = MobUtils.get_shape_names_from_mesh(mesh_instance.mesh)
		
		# get random data
		var mesh_data := get_random_mesh_data(mesh_name, shape_names, mesh_info, 
			gender, type, race, body_data[mesh_data_name])
		
		# link hair color
		if MobConstants.hair_linked_names.has(mesh_name):
			mesh_data.mesh_color = body_data.hair_mesh.mesh_color
		
		# bulk changes
		mesh_data.mesh_name = mesh_data.mesh_name if !bulk_mesh else bulk_mesh[0].mandatory_mesh["BodyBulk"]
		mesh_data.mesh_color = mesh_data.mesh_color if !bulk_color else UIUtils.get_colors_from_color_range(bulk_color[0].mandatory_colors["BodyBulk"]).pick_random()
		
		body_data[mesh_data_name] = mesh_data
	
	return body_data

# get random body or adjust existing
func get_random_equipment(skeleton:Skeleton3D, gender:=MobConstants.Gender.NonBin, type := MobConstants.MobTypes.Civilian, race := MobConstants.MobRaces.Human, eq_data := EquipmentData.new())-> EquipmentData:
	var mesh_data_names := EquipmentData.FIELD_NAMES
	var mesh_names := MobConstants.eq_mesh_info.keys()
	
	var rtg_norms := [MobConstants.race_norms[race], MobConstants.type_norms[type], MobConstants.gender_norms[gender]]
	var bulk_mesh := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_mesh.has("EquipmentBulk"))
	var bulk_color := rtg_norms.filter(func (norms:MeshNormData): return norms.mandatory_colors.has("EquipmentBulk"))
	
	for i in mesh_data_names.size():
		# gather variables 
		var mesh_name:String = mesh_names[i]
		var mesh_data_name:String = mesh_data_names[i]
		var mesh_data: MeshData
		var mesh_info:MobMeshInfo = MobConstants.eq_mesh_info[mesh_name]
		var mesh_instance:MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		var shape_names := []
		if MobConstants.shape_control_meshes.has(mesh_name):
			shape_names = MobUtils.get_shape_names_from_mesh(mesh_instance.mesh)
		
		# get random data
		mesh_data = get_random_mesh_data(mesh_name, shape_names, mesh_info, 
			gender, type, race, eq_data[mesh_data_name])
		
		# bulk changes
		if bulk_mesh:
			mesh_data.mesh_name = bulk_mesh[0].mandatory_mesh["EquipmentBulk"]
		if bulk_color:
			var bulk_range:ColorRangeInfo = bulk_color[0].mandatory_colors["EquipmentBulk"]
			mesh_data.mesh_color = UIUtils.get_colors_from_color_range(bulk_range).pick_random()
		
		eq_data[mesh_data_name] = mesh_data
		
	return eq_data

# get random body or adjust existing
func get_random_mesh_data(mesh_name:String, shape_names:Array, mesh_info:MobMeshInfo, 
		gender:= MobConstants.Gender.NonBin, mob_type := MobConstants.MobTypes.Civilian, race := MobConstants.MobRaces.Human, 
		mesh_data := MeshData.new()) -> MeshData:
	
	var rtg_norms := [MobConstants.race_norms[race], MobConstants.type_norms[mob_type], MobConstants.gender_norms[gender]]
	
	# mesh
	var all_tags = FileUtils.load_json_from_file(mesh_info.mesh_folder+"tag_info.json")
	var selected_tags:Array = all_tags[mesh_data.mesh_name] if all_tags.has(mesh_data.mesh_name) else []
	if !is_mesh_name_within_norms(mesh_data.mesh_name, mesh_name, selected_tags, rtg_norms):
		# get possible meshes
		var all_files: Array
		if MobConstants.half_empty_names.has(mesh_name) && randf()>.5 : # 50% for empty option
			all_files = ["empty"]
		else:
			all_files = FileUtils.get_file_names(mesh_info.mesh_folder) if mesh_info.mesh_folder else [""]
			# add empty option
			if !MobConstants.non_empty_names.has(mesh_name) && mesh_info.mesh_folder:# && !(mesh_name == "Hair" && gender == MobConstants.Gender.Female && randf() > MobConstants.variation_chance): # protection against bald femals
				all_files.insert(0,"empty") # add option to hide mesh
		
		# get random mesh from all_files based on norms
		mesh_data.mesh_name = get_random_mesh_name(all_files, mesh_name, all_tags, rtg_norms)
	
	# color					beard and brow color variations are disabled in get_random_body
	if mesh_info.color_range && !MobConstants.hair_linked_names.has(mesh_name):
		if !is_mesh_color_within_norms(mesh_data.mesh_color, mesh_name, rtg_norms):
			mesh_data.mesh_color = get_random_mesh_color(mesh_info.color_range, mesh_name, rtg_norms)
	
	# shape keys
	if !mesh_info.shape_limits || shape_names.size() == mesh_info.shape_limits.size():
		var shape_array := []
		for shape_id in shape_names.size():
			var shape_value = mesh_data.mesh_shape[shape_id] if mesh_data.mesh_shape else null
			if !shape_value || !is_mesh_shape_within_norms(shape_value, mesh_name, shape_id, rtg_norms):
				var shape_name = shape_names[shape_id]
				var min_r = mesh_info.shape_limits[shape_name][0] if mesh_info.shape_limits else 0
				var max_r = mesh_info.shape_limits[shape_name][1] if mesh_info.shape_limits else 1
				var shape_range = range(min_r*10, max_r*10+1).map(func (ele): return ele/10.0)
				shape_value = get_random_mesh_shape(shape_range, shape_id, mesh_name, rtg_norms)
			# set shape value in array corresponding to shape order in mesh
			shape_array.append(shape_value)
		mesh_data.mesh_shape = shape_array
	elif mesh_info.shape_limits:
		print(mesh_name," has undeclared shape keys. ", shape_names," != ",mesh_info.shape_limits.keys())
	
	return mesh_data

# NEW GET
# get random valid mesh name
func get_random_mesh_name(all_files:Array, mesh_name:String, all_tags:Dictionary, rtg_norms: Array) -> String:
	if randf() > MobConstants.variation_chance || rtg_norms.any(func (norms): return is_enforce_mesh_name.call(norms, mesh_name) || is_enforce_tags.call(norms, all_tags) ):
		for norms:MeshNormData in rtg_norms:
			# check forbidden, mandatory tags
			if norms.mandatory_tags:
				var mandatory_files = all_files.filter(func (file_name): 
					return all_tags.has(file_name) && GeneralUtils.has_all(
						all_tags[file_name],norms.mandatory_tags))
				all_files = mandatory_files if mandatory_files else all_files
			if norms.forbidden_tags:
				var forbidden_files = all_files.filter(func (file_name): 
					return !all_tags.has(file_name) || !GeneralUtils.has_any(
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
func get_random_mesh_color(mesh_color_range:ColorRangeInfo, mesh_name:String, rtg_norms: Array) -> Color:
	for norms:MeshNormData in rtg_norms:
		if norms.mandatory_colors && norms.mandatory_colors.has(mesh_name):
			mesh_color_range = norms.mandatory_colors[mesh_name]
		elif norms.forbidden_colors:
			mesh_color_range = mesh_color_range.filter(func (color): 
				return !norms.forbidden_colors.has(color)
			)
	# pick random hue, saturation, brightness from ranges
	return UIUtils.get_colors_from_color_range(mesh_color_range).pick_random()

# get random valid mesh shape
func get_random_mesh_shape(shape_range:Array, shape_id:int, mesh_name:String, rtg_norms: Array) -> float:
	if randf() > MobConstants.variation_chance || rtg_norms.any(func (norms): return is_enforce_shape.call(norms, mesh_name,shape_id)):
		for norms:MeshNormData in rtg_norms:
			if norms.mandatory_shapes.has(mesh_name) && norms.mandatory_shapes[mesh_name].has(shape_id):
				shape_range = [norms.mandatory_shapes[mesh_name][shape_id]]
			elif norms.forbidden_shapes.has(mesh_name):
				shape_range = shape_range.filter(func (shape_value): return !norms.forbidden_shapes[mesh_name].has(shape_value))
	
	if !shape_range:
		push_warning("Empty shape range for: " + mesh_name + " shape_id: " + str(shape_id))
		return 0
	
	return shape_range.pick_random()

# CHECK
# check validity of mesh_file_name
func is_mesh_name_within_norms(mesh_file_name: String, mesh_name:String, tags:Array, rtg_norms: Array) -> bool:
	if !mesh_file_name:
		return false
	
	for norms:MeshNormData in rtg_norms:
		# check tags
		if norms.mandatory_tags:
			return true if GeneralUtils.has_all(tags, norms.mandatory_tags) else false
		if norms.forbidden_tags && GeneralUtils.has_any(tags, norms.forbidden_tags):
			return false
		# check tags
		if norms.mandatory_mesh.has(mesh_name):
			return true if [norms.mandatory_mesh[mesh_name]].has(mesh_file_name) else false
		if norms.forbidden_mesh.has(mesh_name) && [norms.forbidden_mesh[mesh_name]].has(mesh_file_name):
			return false
	return true

# check validity of color
func is_mesh_color_within_norms(color: Color, mesh_name:String, rtg_norms: Array) -> bool:
	if !color || color == Color(-1, -1, -1):
		return false
	
	for norms:MeshNormData in rtg_norms:
		# check colors
		if norms.mandatory_colors.has(mesh_name):
			return true if [norms.mandatory_colors[mesh_name]].has(color) else false
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
	adjust_mob_to_race(mob, mob_data.race)
	set_body_data(mob_data.body_data, mob)
	set_equipment_data(mob_data.equipment_data, mob)

func set_body_data(body_data:BodyData, mob:Mob):
	mob.body_data = body_data
	var skeleton:Skeleton3D = mob.get_node("body/Armature/Skeleton3D")
	var mesh_names:Array = MobConstants.body_mesh_info.keys()
	var mesh_data_names := BodyData.FIELD_NAMES
	
	for i in mesh_data_names.size():
		var mesh_name:String = mesh_names[i]
		var mesh_data:MeshData = body_data[mesh_data_names[i]]
		var mesh_instance:MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		if mesh_instance:
			set_mesh_data(mesh_data, mesh_name, mesh_instance)

func set_equipment_data(eq_data:EquipmentData, mob:Mob):
	mob.equipment_data = eq_data
	var skeleton:Skeleton3D = mob.get_node("body/Armature/Skeleton3D")
	var mesh_names:Array = MobConstants.eq_mesh_info.keys()
	var mesh_datas := EquipmentData.FIELD_NAMES
	
	for i in mesh_datas.size():
		var mesh_name:String = mesh_names[i]
		var mesh_data:MeshData = eq_data[mesh_datas[i]]
		var mesh_instance:MeshInstance3D = MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
		if mesh_instance:
			set_mesh_data(mesh_data, mesh_name, mesh_instance)

func set_mesh_data(mesh_data:MeshData, mesh_name:String,mesh_instance:MeshInstance3D):
	# mesh
	if mesh_data.mesh_name:
		var is_body_mesh := MobConstants.body_mesh_info.has(mesh_name)
		var mesh_info:MobMeshInfo= MobConstants.body_mesh_info[mesh_name] if is_body_mesh else MobConstants.eq_mesh_info[mesh_name]
		if mesh_info.mesh_folder:
			MobUtils.set_mesh(mesh_data.mesh_name, mesh_instance, mesh_info.mesh_folder)
		elif mesh_data.mesh_name == "empty":
			mesh_instance.hide()
	
	# color
	if mesh_data.has_color():
		var material_nr = 0 if mesh_name == "Body" else -1
		MobUtils.set_mesh_color(mesh_data.mesh_color, mesh_instance, material_nr)
	
	# shape keys
	if mesh_data.mesh_shape:
		var shape_names = MobUtils.get_shape_names_from_mesh(mesh_instance.mesh)
		if mesh_data.mesh_shape.size() != shape_names.size():
			print(mesh_name+" shapes differ in saved data and mesh")
			return
		
		for i in mesh_data.mesh_shape.size():
			var value:float = float(mesh_data.mesh_shape[i])
			var shape_name:String = shape_names[i]
			MobUtils.set_skeleton_shape_key(value,shape_name,mesh_instance.get_parent())

# ADJUST
# adjust mob model in a way not covered by body and eq data
func adjust_mob_to_race(mob:Mob, race:int):
	var dict:Dictionary =  MobConstants.race_action_dict[race]
	var skeleton = mob.get_node("body/Armature/Skeleton3D")
	# show_monster_body
	var show_monster_body:bool = dict.has("show_monster_body") && dict.show_monster_body
	skeleton.get_node("monster-body").visible = show_monster_body
	var body_meshes := ["Eyelashes","Brows","Eyes"]
	body_meshes.append_array(MobConstants.meshes_with_skin) # meshes outside bodydata
	for child in skeleton.get_children():
		if body_meshes.has(child.name):
			child.visible = !show_monster_body
	
	# change scale
	mob.scale = Vector3.ONE if !dict.has("scale") else Vector3.ONE*dict.scale
	
	# disable details texture on body for statues
	var body_mesh:MeshInstance3D = skeleton.get_node("Top")
	var material:StandardMaterial3D = body_mesh.get_active_material(0)
	material.albedo_texture_msdf = [MobConstants.MobRaces.Statue,MobConstants.MobRaces.Spirit].has(race)
	
	# change body colors outside of body_data
	var def_body_colors := {"Eyes": {0:Color.WHITE, 2:Color.BLACK}, "Eyelashes":{0:Color.BLACK}}
	def_body_colors.Eyes[0]=Color.WHITE if !dict.has("eye_whites") else dict.eye_whites
	def_body_colors.Eyes[2]=Color.BLACK if !dict.has("eye_pupil") else dict.eye_pupil
	# set colors to all meshes outside body data TODO not needed really
	for mesh_name in def_body_colors.keys():
		for mat_nr in def_body_colors[mesh_name].keys():
			var color = def_body_colors[mesh_name][mat_nr] if race != MobConstants.MobRaces.Statue else MobConstants.Color_Statue_Grey
			MobUtils.set_mesh_color(color, skeleton.get_node(mesh_name),mat_nr)
