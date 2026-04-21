extends Node

# DESERIALISE save data from node/resource to json
func deserialise_abstract(val):
	if val is Resource and val.get_script():
		return deserialise_resource(val)
	elif val is Dictionary:
		return deserialise_dict(val)
	elif val is Array:
		return deserialise_array(val)
	elif val is Vector2:
		return "Vector2" + str(val[0]) + "," + str(val[1])
	elif val is Vector3 || val is Vector3i:
		return "Vector3" + str(val[0]) + "," + str(val[1]) + "," + str(val[2])
	elif val is Color:
		return "Color" + str(val[0]) + "," + str(val[1]) + "," + str(val[2]) + "," + str(val[3])
	elif !val:
		return ""
	else:
		if val is String:
			val = val.replace("\"", "")
		return val

func deserialise_resource(res: Resource):
	var new_dict := {}
	var script_path: String = res.get_script().resource_path
	new_dict["NodeData"] = script_path
	var default_res = load(script_path).new()
	
	# Use FIELD_NAMES const if available, else fall back to property list
	var fields: Array = []
	if "FIELD_NAMES" in res:
		fields = res.FIELD_NAMES
	else:
		for prop in res.get_property_list():
			if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				fields.append(prop.name)
	
	for key in fields:
		var val = res.get(key)
		var default_val = default_res.get(key)
		if key == "biome_name" || key == "cur_biome" || val != default_val:
			new_dict[key] = deserialise_abstract(val)
	return new_dict

func deserialise_dict(dict: Dictionary):
	var new_dict = {}
	for key in dict.keys():
		var new_key = deserialise_abstract(key)
		new_dict[new_key] = deserialise_abstract(dict[key])
	return new_dict

func deserialise_array(array: Array):
	var new_arr = []
	for val in array:
		new_arr.append(deserialise_abstract(val))
	return new_arr
