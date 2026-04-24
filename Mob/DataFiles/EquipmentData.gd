extends Resource
class_name EquipmentData

var top_mesh: MeshData
var bottom_mesh: MeshData
var shoe_mesh: MeshData
var hat_mesh: MeshData
var r_hand_mesh: MeshData
var l_hand_mesh: MeshData
var accessory_mesh: MeshData

func _init(_top_mesh := MeshData.new(), _bottom_mesh := MeshData.new(), _shoe_mesh := MeshData.new(), _hat_mesh := MeshData.new(),
	_r_hand_mesh := MeshData.new(), _l_hand_mesh := MeshData.new(), _accessory_mesh := MeshData.new()):
	top_mesh = _top_mesh
	bottom_mesh = _bottom_mesh
	shoe_mesh = _shoe_mesh
	hat_mesh = _hat_mesh
	accessory_mesh = _accessory_mesh
	r_hand_mesh = _r_hand_mesh
	l_hand_mesh = _l_hand_mesh
