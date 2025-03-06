extends Node
class_name MeshData

var mesh_color:Color
var mesh_name:String
var mesh_shape:Array

func _init(_mesh_color:=Color(-1,-1,-1), _mesh_name:="", _mesh_shape:=[]):
	mesh_color = _mesh_color
	mesh_name = _mesh_name
	mesh_shape = _mesh_shape.map(func (val): return float(val))
