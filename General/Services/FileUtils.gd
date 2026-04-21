extends Node
var serializer = load("res://General/Services/Serializer.gd").new()
var deserializer = load("res://General/Services/Deserializer.gd").new()

# Cache for loaded resources
var _cache := {}

func deserialize_and_save(serialized_data, path:="", file_name:="file.txt"):
	var json_data = deserializer.deserialise_abstract(serialized_data)
	if json_data != {}:
		FileUtils.save_to_file(str(json_data),path, file_name)

func serialize_and_load(file_name:="file.txt", path:=""):
	var file = FileAccess.open(path+ file_name,FileAccess.READ)
	if !file:
		print("Failed to open file: "+path+file_name)
		return {}
	var result = JSON.parse_string(file.get_as_text())
	if !result:
		print("Failed to load save data from file: "+file_name)
		return {}
	print("Loading save data from file: ",file_name)
	return serializer.serialize_abstract(result)

# save text to a file with a given location name and format
func save_to_file(text:String, path:="res://",file_name:="file.txt"):
	var file = FileAccess.open(path+file_name,FileAccess.WRITE)
	file.store_string(str(text))

# Load a mesh resource from a .tres file path, with caching
func load_mesh_from_file(file_path: String):
	if _cache.has(file_path):
		return _cache[file_path]
	if !ResourceLoader.exists(file_path):
		return null
	var res = load(file_path)
	_cache[file_path] = res
	return res

# Load JSON data from a file, returns Dictionary (empty if not found)
func load_json_from_file(file_path: String) -> Dictionary:
	if _cache.has(file_path):
		return _cache[file_path]
	if !FileAccess.file_exists(file_path):
		_cache[file_path] = {}
		return {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	if !file:
		_cache[file_path] = {}
		return {}
	var result = JSON.parse_string(file.get_as_text())
	if result == null:
		result = {}
	_cache[file_path] = result
	return result

# Get file names (without extension) from a directory of .tres files
func get_file_names(folder_path: String) -> Array[String]:
	if !folder_path:
		return []
	var cache_key = "dir:" + folder_path
	if _cache.has(cache_key):
		return _cache[cache_key].duplicate()
	var names :Array[String]= []
	var dir = DirAccess.open(folder_path)
	if !dir:
		_cache[cache_key] = names
		return names
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and file_name.ends_with(".tres"):
			names.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	names.sort()
	_cache[cache_key] = names
	return names.duplicate()

# Load an image file as a Texture2D
func load_image_from_file(file_path: String) -> Texture2D:
	if _cache.has(file_path):
		return _cache[file_path]
	if !ResourceLoader.exists(file_path):
		return null
	var tex = load(file_path)
	_cache[file_path] = tex
	return tex
