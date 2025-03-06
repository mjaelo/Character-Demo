extends Node

# DESERIALISE save data from node to json
func deserialise_abstract(val):
	if val is Node:
		return deserialise_node(val) 
	elif val is Dictionary:
		return deserialise_dict(val)
	elif val is Array:
		return deserialise_array(val)
	elif val is Vector2:
		return "Vector2"+str(val[0])+","+str(val[1])
	elif val is Vector3 || val is Vector3i:
		return "Vector3"+str(val[0])+","+str(val[1])+","+str(val[2])
	elif val is Color:
		return "Color"+str(val[0])+","+str(val[1])+","+str(val[2])+","+str(val[3])
	elif !val:
		return ""
	else:
		if val is String:
			val = val.replace("\"","") # remove \
		return val

func deserialise_node(node:Node):
	var args := Utils.get_user_defined_variables(node)
	var new_node := {}
	var node_path:String = node.get_script().resource_path
	new_node["NodeData"] = node_path
	var node2 = load(node_path).new()
	for key in args:
		if key == "biome_name" || key == "cur_biome" || !Utils.node_equals(node[key],node2[key]):
			new_node[key] = deserialise_abstract(node[key])
	return new_node

func deserialise_dict(dict:Dictionary):
	var new_dict = {}
	for key in dict.keys():
		var new_key = deserialise_abstract(key)
		new_dict[new_key] = deserialise_abstract(dict[key])
	return new_dict

func deserialise_array(array:Array):
	var new_arr = []
	for val in array:
		new_arr.append(deserialise_abstract(val))
	return new_arr
