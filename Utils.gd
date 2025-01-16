extends Node

var cached_meshes := {} # mesh_name : ArrayMesh
var cached_meshes_order := [] # loaded meshes from oldest to newest
const cache_limit := 50


# TODO use it whne input ist used
func get_key_from_event(event: InputEvent) -> int:
	if event is InputEventKey:
		return event.keycode
	if event is InputEventMouseButton:
		return event.button_mask
	return 0

# TODO use it for data files. possibly other places
func get_user_defined_variables(instance:Node) ->Array:
	var result := []
	var properties:Array = instance.get_property_list()
	var found_script := false
	for property in properties:
		if property.type != TYPE_NIL:
			if found_script:
				result.append(property.name)
			elif property.name == "script":
				found_script = true
	return result

# READ DATA FROM FILES
func get_file_names(folder_path: String, extention := ".tres", delete_extention := true)->Array:
	var dir = DirAccess.open(folder_path)
	if dir != null:
		dir.list_dir_begin()
		var file_names = []
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.ends_with(extention):
				file_name = file_name.trim_suffix(extention) if delete_extention else file_name
				file_names.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
		return file_names
	return []

func read_json_file(file_path: String) -> Dictionary:
	# Open the file for reading
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file:
		# Read the entire file content as text
		var file_content := file.get_as_text()
		file.close()
		
		# Parse the JSON content
		var json_result = JSON.parse_string(file_content)
		
		# Check if the JSON parsing was successful
		if json_result:
			return json_result
	return {}

func load_mesh(file_path:String) -> ArrayMesh:
	var loaded_mesh = get_cached_data(file_path,cached_meshes)
	if !loaded_mesh:
		loaded_mesh = ResourceLoader.load(file_path, "Mesh") 
		set_cached_data(loaded_mesh,file_path,cached_meshes)
	return loaded_mesh

# CACHE
# TODO () add cache limit. move last cached object to front. when over limit, delete oldest cached one.
func set_cached_data(data, data_name:String, cache_dict:Dictionary):
	if data:
		if !cache_dict.has(data_name):
			# delete cached_mesh if over the limit
			if cached_meshes_order.size()>=cache_limit:
				var oldest_key:String = cached_meshes_order[0]
				cached_meshes_order.remove_at(0)
				cached_meshes.erase(oldest_key)
			
			# save data
			cache_dict[data_name] = data
			cached_meshes_order.append(data_name)

func get_cached_data(data_name:String, cache_dict:Dictionary):
	if cache_dict.has(data_name):
		# change data order
		if cached_meshes_order[-1] != data_name:
			cached_meshes_order.erase(data_name) 
			cached_meshes_order.append(data_name)
		return cache_dict[data_name]

# TODO () call when crossing biome
func clear_cache():
	cached_meshes = {}
	cached_meshes_order = []
