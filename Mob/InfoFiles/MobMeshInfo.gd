extends Resource
class_name MobMeshInfo

var mesh_folder: String
var color_range: ColorRangeInfo
var shape_limits: Dictionary # {"shape_name": [min, max]}

func _init(_mesh_folder:String,_color_range:ColorRangeInfo = null,_shape_limits:={}):
	mesh_folder = _mesh_folder
	color_range = _color_range
	shape_limits = _shape_limits
