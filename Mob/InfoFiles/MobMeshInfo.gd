extends Resource
class_name MobMeshInfo

var file_folder: String
var colors: Array[Color] # pre-expanded array of valid colors
var shapes: Dictionary # {"shape_name": Array[float]} pre-expanded arrays of valid shape values

# Pass ColorRangeInfo or null for colors, and {"name": Vector2(min,max)} for shapes.
# Both get expanded into arrays at init time.
func _init(_file_folder: String, _color_range: ColorRangeInfo = null, _shape_limits := {}):
	file_folder = _file_folder
	if _color_range:
		colors.append_array(UIUtils.get_colors_from_color_range(_color_range))
	shapes = {}
	for shape_name: String in _shape_limits:
		var limits: Vector2 = _shape_limits[shape_name]
		shapes[shape_name] = _expand_float_range(limits)

static func _expand_float_range(limits: Vector2) -> Array[float]:
	var result: Array[float] = []
	for v in range(int(limits.x * 10), int(limits.y * 10) + 1):
		result.append(v / 10.0)
	return result
