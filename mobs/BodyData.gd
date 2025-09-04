extends Node
class_name BodyData

var body_mesh: MeshData # ["Body Shape","Body Mass","Body Muscles"]
var head_mesh: MeshData # ["Jaw Shape", "Face Length","Eye Lower Lid", "Eye Upper Lid","Eye Edge", "Lips Width"]
var eye_mesh: MeshData
var lashes_mesh: MeshData

var hair_mesh: MeshData
var beard_mesh: MeshData
var brow_mesh: MeshData # ["Thickness","Inner Height","Outer Height"]

func _init(_body_mesh := MeshData.new(), _head_mesh := MeshData.new(), _eye_mesh := MeshData.new(), _lashes_mesh := MeshData.new(), 
	_hair_mesh := MeshData.new(), _beard_mesh := MeshData.new(), _brow_mesh := MeshData.new()):
	body_mesh = _body_mesh
	head_mesh = _head_mesh
	eye_mesh = _eye_mesh
	lashes_mesh = _lashes_mesh
	
	hair_mesh = _hair_mesh
	beard_mesh = _beard_mesh
	brow_mesh = _brow_mesh
