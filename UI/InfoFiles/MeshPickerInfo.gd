extends Resource
class_name MeshPickerInfo

var mesh_name: String
var has_file_picker: bool
var has_color_picker: bool
var has_shape_picker: bool

func _init(_mesh_name:String,_has_file_picker := false, _has_color_picker := false, _has_shape_picker := false):
	mesh_name = _mesh_name
	has_file_picker = _has_file_picker
	has_color_picker = _has_color_picker
	has_shape_picker = _has_shape_picker
