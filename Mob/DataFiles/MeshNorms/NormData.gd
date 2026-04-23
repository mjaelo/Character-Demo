extends Resource
class_name NormData

var type: MobConstants.NormType
var value # dictionary (shape->color/shapeid->value) or array of tags
var forbidden: bool # false = mandatory, true = forbidden
var enforce: bool # if true, always check this norm (ignore variation_chance)

func _init(_type: MobConstants.NormType, _value = null, _forbidden := false, _enforce := false):
	type = _type
	value = _value
	forbidden = _forbidden
	enforce = _enforce
