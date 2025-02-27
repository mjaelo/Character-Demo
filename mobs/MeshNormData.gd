extends Node
class_name MeshNormData


var mandatory_tags: Array
var forbidden_tags: Array
var mandatory_mesh: Dictionary
var forbidden_mesh: Dictionary
var mandatory_colors: Dictionary
var forbidden_colors: Dictionary
var mandatory_shapes: Dictionary
var forbidden_shapes: Dictionary
var enforce: Dictionary

func _init(_mandatory_tags := [], _forbidden_tags := [], _mandatory_mesh := {}, _forbidden_mesh := {}, 
		_mandatory_colors := {}, _forbidden_colors := {}, _mandatory_shapes := {}, _forbidden_shapes := {},
		_enforce := {}):
	mandatory_tags = _mandatory_tags
	forbidden_tags = _forbidden_tags
	mandatory_mesh = _mandatory_mesh
	forbidden_mesh = _forbidden_mesh
	mandatory_colors = _mandatory_colors
	forbidden_colors = _forbidden_colors
	mandatory_shapes = _mandatory_shapes
	forbidden_shapes = _forbidden_shapes
	enforce = _enforce
