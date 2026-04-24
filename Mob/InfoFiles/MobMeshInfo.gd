extends Resource
class_name MobMeshInfo

var field_name: String
var file_folder: String
var colors: Array[Color] # pre-expanded array of valid colors
var shapes: Dictionary # {"shape_name": Array[float]} pre-expanded arrays of valid shape values

# Pass ColorRangeInfo or null for colors, and {"name": Vector2(min,max)} for shapes.
# Both get expanded into arrays at init time.
func _init(_field_name:String, _file_folder: String, _color_range: ColorRangeInfo = null, _shape_limits := {}):
	field_name = _field_name
	file_folder = _file_folder
	if _color_range:
		colors.append_array(MobUtils.get_colors_from_color_range(_color_range))
	shapes = {}
	for shape_name: String in _shape_limits:
		var limits: Vector2 = _shape_limits[shape_name]
		shapes[shape_name] = MobUtils._expand_float_range(limits)
