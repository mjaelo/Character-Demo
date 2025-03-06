extends Node

var serializer = load("res://general/Files/Serializer.gd").new()
var deserializer = load("res://general/Files/Deserializer.gd").new()

func deserialize_and_save(serialized_data, path:="", file_name:="file.txt"):
	var json_data = deserializer.deserialise_abstract(serialized_data)
	if json_data != {}:
		FileUtils.save_to_file(str(json_data),path, file_name)

func serialize_and_load(file_name:="file.txt", path:=""):
	var file = FileAccess.open(path+ file_name,FileAccess.READ)
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
