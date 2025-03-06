extends Node

var cached_dict := {
	"Meshes": CachedData.new(),
	"JSON": CachedData.new(),
	"Images": CachedData.new()
}

# TODO use it whne input ist used
func get_key_from_event(event: InputEvent) -> int:
	if event is InputEventKey:
		return event.keycode
	if event is InputEventMouseButton:
		return event.button_mask
	return 0

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

func has_all(main_array: Array, elements_array: Array) -> bool:
	for element in elements_array:
		if element not in main_array:
			return false
	return true

func has_any(main_array: Array, elements_array: Array) -> bool:
	for element in elements_array:
		if element in main_array:
			return true
	return false

# compare two objects, no mather their type
func node_equals(node1, node2) -> bool:
	if typeof(node1) != typeof(node2):
		return false
	if node1 is Node:
		if node1.name != node2.name || node1.get_path() != node2.get_path():
			return false
		var init_method = node1.get_method_list().filter(func (fun): return fun.name == "_init")[1]
		var args: Array = init_method.args.map(func (arg):  return arg.name.erase(0))
		var init_method2 = node2.get_method_list().filter(func (fun): return fun.name == "_init")[1]
		var args2: Array = init_method2.args.map(func (arg):  return arg.name.erase(0))
		if !node_equals(args,args2):
			return false
		
		for arg in args:
			if !node_equals(node1[arg],node2[arg]):
				return false
	elif node1 is Dictionary:
		for key in node1.keys():
			if node2 is Dictionary && !node2.has(key):
				return false
			elif node2 is Node && !node2.has_node(key):
				return false
			if !node_equals(node1[key],node2[key]):
				return false
	elif node1 is Array || node1 is Vector2 || node1 is Vector3:
		var size := 1
		if node1 is Vector2:
			size = 2
		elif node1 is Vector3:
			size = 3
		else:
			size = node1.size()
			if node2.size() != size:
				return false
		for nr in size:
			if !node_equals(node1[nr],node2[nr]):
				return false
	elif node1 != node2:
		return false
	return true

# READ DATA FROM FILES TODO move to FileUtils
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

func load_json_from_file(file_path: String) -> Dictionary:
	var temp = load_data_from_file(file_path, "JSON", cached_dict.JSON)
	return temp

func json_file_loader(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file:
		var file_content := file.get_as_text()
		file.close()
		var json_result = JSON.parse_string(file_content)
		if json_result:
			return json_result
	return {}

func load_mesh_from_file(file_path:String) -> ArrayMesh:
	return load_data_from_file(file_path, "Mesh", cached_dict.Meshes)

func load_image_from_file(file_path:String) -> Texture2D:
	return load_data_from_file(file_path, "Image", cached_dict.Images)

func load_data_from_file(file_path:String, file_type:String, cached_data:CachedData):
	var loaded_data = get_cached_data(file_path,cached_data)
	if !loaded_data:
		loaded_data = ResourceLoader.load(file_path, file_type) if file_type != "JSON" else json_file_loader(file_path)
		set_cached_data(loaded_data,file_path,cached_data)
	return loaded_data

# CACHE
# move last cached object to front. when over limit, delete oldest cached one.
func set_cached_data(data, data_name:String, cached_data:CachedData):
	if data:
		if !cached_data.cached_data.has(data_name):
			# delete cached_mesh if over the limit
			if cached_data.cached_order.size() >= cached_data.cached_limit:
				var oldest_key:String = cached_data.cached_order[0]
				cached_data.cached_order.remove_at(0)
				cached_data.Meshes.cached_data.erase(oldest_key) # TODO more caches
			
			# save data
			cached_data.cached_data[data_name] = data
			cached_data.cached_order.append(data_name)

func get_cached_data(data_name:String, cached_data:CachedData):
	if cached_data.cached_data.has(data_name):
		# change data order
		if cached_data.cached_order[-1] != data_name:
			cached_data.cached_order.erase(data_name) 
			cached_data.cached_order.append(data_name)
		return cached_data.cached_data[data_name]

# TODO () call when crossing biome
func clear_cache():
	cached_dict.values().map(func (old_cache:CachedData): return CachedData.new())
