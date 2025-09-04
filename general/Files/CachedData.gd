extends Node
class_name CachedData

var cached_data:Dictionary  # mesh_name : ArrayMesh
var cached_order:Array # loaded meshes from oldest to newest
var cached_limit:int

func _init(_cached_data:={}, _cached_order:=[], _cached_limit:=50):
	cached_data = _cached_data
	cached_order = _cached_order
	cached_limit = _cached_limit
