extends Resource
class_name CachedData

var cached_data: Dictionary = {}
var cached_order: Array = []
var cached_limit: int = 50

func _init(_cached_data := {}, _cached_order := [], _cached_limit := 50):
	cached_data = _cached_data
	cached_order = _cached_order
	cached_limit = _cached_limit
