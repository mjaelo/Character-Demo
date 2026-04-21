extends Node

# SERIALISE load data from json to node
func serialize_abstract(val):
	if val is Dictionary:
		return serialize_dict(val)
	elif val is Array:
		return serialize_array(val)
	elif val is String:
		return serialise_string(val)
	else:
		return val

func serialize_dict(dict):
	if dict.has("NodeData"):
		return serialize_node(dict,dict["NodeData"])
	var new_dict = {}
	for key in dict.keys():
		var new_key = serialise_string(key)
		new_dict[new_key] = serialize_abstract(dict[key])
	return new_dict

func serialize_node(dict:Dictionary,script_path:String):
	var empty_obj = load(script_path).new()
	dict.erase("NodeData")
	for key in dict.keys():
		var new_val = serialize_abstract(dict[key])
		if !new_val && empty_obj[key] is bool:
			empty_obj[key] = false
		else:
			empty_obj[key] = new_val
	return empty_obj

func serialise_string(key:String):
	if key.begins_with("Vector2"):
		var tab = key.split("Vector2")[1].split(",")
		return Vector2(float(tab[0]),float(tab[1]))
	elif key.begins_with("Vector3"):
		var tab = key.split("Vector3")[1].split(",")
		return Vector3(float(tab[0]),float(tab[1]),float(tab[2]))
	elif key.begins_with("Color"):
		var tab = key.split("Color")[1].split(",")
		return Color(float(tab[0]),float(tab[1]),float(tab[2]),float(tab[3]))
	elif key == "true":
		return true
	elif key == "false":
		return false
	else:
		return key.replace("/","")

func serialize_array(array:Array):
	var new_array = []
	for item in array:
		new_array.append(serialize_abstract(item))
	return new_array
