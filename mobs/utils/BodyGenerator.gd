extends Node

const gender_tags := ["masculine","feminine"]
const gender_shape_normals := { # masc, fem normals
	"Body Mass": [0,0],
	"Body Muscles": [0,0],
	"enforce": [["Body Shape"],[]], # additional enforce norms for [male, female]
	"Body Shape": [0,.5], 
	"Lips Width": [-1,1], 
	"Brow Thickness": [1,0]
}

# TODO () get shapes from mesh and here just check if has min/max assigned?
var body_mesh_info := {
	"Eyes": {
		"color_range": MobConstants.eyes_color_ranges
	},
	"Eyelashes": {
		"mesh_folder": "res://mobs/body/face/lashes/",
	},
	"Body": {
		"color_range": MobConstants.skin_color_ranges,
		"shape_limits":{
			"Body Shape": [0,1],"Body Mass": [-.5,1],"Body Muscles": [-.5,1],
			"Lips Width": [-1,1],"Jaw Shape": [-1,1], "Face Length": [-.5,.5],
			"Eye Lower Lid": [-1,1], "Eye Upper Lid": [-1,1],"Eye Edge": [-1,1]
		}
	},
	"Hair": {
		"mesh_folder": "res://mobs/body/hair/",
		"color_range": MobConstants.hair_color_ranges
	},
	"Brows": {
		"color_range": MobConstants.hair_color_ranges,
	},
	"Beard": {
		"color_range": MobConstants.hair_color_ranges,
		"mesh_folder": "res://mobs/body/face/beard/",
	},
}

var eq_mesh_info := {
		"Top": {
			"mesh_folder": "res://mobs/body/top/",
			"color_range": MobConstants.clothes_color_ranges
		},
		"Bottom": {
			"mesh_folder": "res://mobs/body/bottom/",
			"color_range": MobConstants.clothes_color_ranges
		},
		"Shoes": {
			"mesh_folder": "res://mobs/body/shoes/",
			"color_range": MobConstants.clothes_color_ranges
		},
		"Hat": {
			"mesh_folder": "res://mobs/body/hat/",
			"color_range": MobConstants.clothes_color_ranges
		},
		"Right Hand": {
			"mesh_folder": "res://mobs/body/r_hand/",
		},
		"Left Hand": {
			"mesh_folder": "res://mobs/body/l_hand/",
		},
}

func get_random_body(skeleton:Skeleton3D, gender:int)-> BodyData:
	var body_data := BodyData.new()
	var mesh_array := []
	
	for mesh_name in body_mesh_info.keys():
		var mesh_info:Dictionary = body_mesh_info[mesh_name]
		var mesh_instance = skeleton.get_node(mesh_name)
		var mesh_data = get_random_mesh_data(mesh_name,	mesh_instance, mesh_info, gender)
		mesh_array.append(mesh_data)
	
	# TODO i dont like doing it by array
	body_data.eye_mesh = mesh_array[0]
	body_data.lashes_mesh = mesh_array[1]
	body_data.body_mesh = mesh_array[2]
	body_data.hair_mesh = mesh_array[3]
	body_data.brow_mesh = mesh_array[4]
	body_data.beard_mesh = mesh_array[5]
	
	return body_data

func get_random_equipment(skeleton:Skeleton3D, gender:int, type := MobConstants.MobTypes.Civilian)-> EquipmentData:
	var eq_data := EquipmentData.new()
	var mesh_array := []
	
	for mesh_name:String in eq_mesh_info.keys():
		var mesh_data: MeshData
		var mesh_info:Dictionary = eq_mesh_info[mesh_name]
		var mesh_instance = skeleton.get_node(mesh_name)
		
		if MobConstants.hand_names.has(mesh_name): # get embedded mesh TODO () duplicate in Setup
			mesh_instance = mesh_instance.get_parent().get_node("Hip" if MobConstants.hand_names[0] == mesh_name else "Back").get_child(0).get_child(0)
		
		mesh_data = get_random_mesh_data(mesh_name, mesh_instance,	mesh_info, gender, type)
		
		# TODO () check if done by tags
		#if MobConstants.hand_names.has(mesh_name):
			#if type != MobConstants.MobTypes.Guard:
				#mesh_data.mesh_name = "empty"
		
		mesh_array.append(mesh_data) # TODO () must be a better way
	
	eq_data.top_mesh = mesh_array[0]
	eq_data.bottom_mesh = mesh_array[1]
	eq_data.shoe_mesh = mesh_array[2]
	eq_data.hat_mesh = mesh_array[3]
	eq_data.r_hand_mesh = mesh_array[4]
	eq_data.l_hand_mesh = mesh_array[5]
	
	return eq_data

# TODO use mesh_instance.mesh instead of mesh_instance
func get_random_mesh_data(mesh_name:String, mesh_instance:MeshInstance3D, mesh_info:Dictionary, gender:=0,mob_type := MobConstants.MobTypes.Civilian) -> MeshData:
	var mesh_data := MeshData.new()
	
	# mesh
	if mesh_info.has("mesh_folder"):
		# get possible meshes
		var all_files:Array
		if MobConstants.half_empty_names.has(mesh_name) && randf()>.5 : # 50% for empty option
			all_files = ["empty"]
		else:
			all_files = get_filtered_mesh_names(mesh_info.mesh_folder, mesh_name, gender, mob_type)
		
		# set mesh
		mesh_data.mesh_name = all_files.pick_random()
	
	# color
	if mesh_info.has("color_range") && !MobConstants.hair_linked_names.has(mesh_name): # beard and brow color variations are disabled in get_random_body
		# transform float min max values to floar range between min max
		var color_range =  mesh_info.color_range.values().map(
			func (minmax:Array): return range(minmax[0]*100, minmax[1]*100).map(
				func (e): return e/100.0))
		# pick random hue, saturation, brightness from ranges
		mesh_data.mesh_color = Color.from_hsv(
				color_range[0].pick_random(),
				color_range[1].pick_random(),
				color_range[2].pick_random()
			)
	
	# shape keys
	if mesh_instance.mesh:
		var shape_names = range(0, mesh_instance.mesh.get_blend_shape_count()).map(
			func (i): return mesh_instance.mesh.get_blend_shape_name(i)
		)
		var shape_array := []
		for shape_name in shape_names:
			# get enforced norms if available and not varianced
			var shape_value = get_gendered_shape_value(shape_name,gender)
			# otherwise get random value from range
			if shape_value == null:
				var min_r = mesh_info.shape_limits[shape_name][0] if mesh_info.has("shape_limits") else 0
				var max_r = mesh_info.shape_limits[shape_name][1] if mesh_info.has("shape_limits") else 1
				shape_value = range(min_r*10, max_r*10+1).pick_random()/10.0
			# set shape value in array corresponding to shape order in mesh
			shape_array.append(shape_value)
		mesh_data.mesh_shape = shape_array
	
	return mesh_data

func get_gendered_shape_value(picker_name:String, gender:=0):	
	gender = (gender+1)/2.0 if gender else [0,1].pick_random()
	if gender_shape_normals.has(picker_name) && randf() > MobConstants.variation_chance || (
		gender_shape_normals.enforce[gender].has(picker_name) && randf() > MobConstants.variation_chance): # extra protection against men with boobs
		return gender_shape_normals[picker_name][gender]
	return null

func get_filtered_mesh_names(mesh_path:String, mesh_name:String,gender:int,mob_type := MobConstants.MobTypes.Civilian) -> Array:
	var all_files := Utils.get_file_names(mesh_path)
		
	# add empty option
	if !MobConstants.non_empty_names.has(mesh_name) && !(mesh_name == "Hair" && gender == 1 && randf() > MobConstants.variation_chance): # protection against bald femals
		all_files.insert(0,"empty") # add option to hide mesh
	
	# filter out unfitting tags
	var tag_info := Utils.read_json_file(mesh_path+"tag_info.json")
	if tag_info:
		var forbidden_tags := []
		var mandatory_tags := []
		
		# filter opposite gender out
		var gender_i = (gender*-1+1)/2.0 if gender else [0,1].pick_random()
		forbidden_tags.append(gender_tags[gender_i])
		
		# filter unfitting types out (leave only Civilian and mob_type)
		var forbidden_mob_types := MobConstants.MobTypes.values().filter(func (type): 
			return type != mob_type && type != MobConstants.MobTypes.Civilian).map(func (id):
				return MobConstants.MobTypes.keys()[id])
		forbidden_tags.append_array(forbidden_mob_types)
		
		# filter type in
		mandatory_tags.append(MobConstants.MobTypes.keys()[mob_type])
		
		# filter out forbidden files and leave the rest
		all_files = all_files.filter(func (f_name): 
			return !tag_info.has(f_name) || forbidden_tags.all(func (tag): # there are no tags for this mesh
				return tag_info[f_name].find(tag) == -1) # or all forbidden tags are not found in tag list
			)
		# filter in mandatory files and remove the rest
		var mandatory_files = all_files.filter(func (f_name): 
			return tag_info.has(f_name) && mandatory_tags.all(func (tag): # there are no tags for this mesh
				return tag_info[f_name].find(tag) != -1) # or all mandatory tags are present
			)
		if mandatory_files: # if none found, pick from the rest
			all_files = mandatory_files
	
	return all_files
