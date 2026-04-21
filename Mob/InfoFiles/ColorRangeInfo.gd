extends Resource
class_name ColorRangeInfo

var hue: Vector2
var saturation: Vector2
var brightness: Vector2
var alpha: Vector2

func _init(_hue:=Vector2.ZERO,_saturation:=Vector2.ZERO,_brightness:=Vector2.ZERO, _alpha := Vector2.ONE):
	hue = _hue
	saturation = _saturation
	brightness = _brightness
	alpha = _alpha
