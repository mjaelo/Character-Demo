extends Node

const main_materials := { # TODO () eyes are not here...
	"merchant-top": 2,
	"merchant-hat": 2,
	"guard-bottom": 1,
	"guard-top": 2
}
const full_hats := ["guard-hat"] # TODO () use tag full-hat instead. Also, when this tag detected, hide whole hair?

# SET MESH DATA
func set_mesh(file_name:String, mesh_instance:MeshInstance3D, path:String, is_hair_bald := false):
	# set mesh from file
	if file_name == "empty": # TODO duplicate in some places
		mesh_instance.hide()
	else:
		var file_path = path+file_name+".tres"
		var new_mesh:ArrayMesh = Utils.load_mesh(file_path)
		if new_mesh:
			var color = get_mesh_color(mesh_instance)
			mesh_instance.show()
			mesh_instance.mesh = new_mesh
			
			set_mesh_color(color,mesh_instance)
		else:
			mesh_instance.hide()
			print(file_path," not found")
	
	# handle specific case mashes
	if mesh_instance.name == "Hat": 
		adjust_hair_hider(file_name,mesh_instance,mesh_instance.get_parent(),is_hair_bald)
	
	# adjust sword collision shape
	if mesh_instance.name == "Sword":
		var col_shape:CollisionShape3D = mesh_instance.get_node("StaticBody3D/CollisionShape3D")
		if mesh_instance.visible:
			col_shape.shape = mesh_instance.mesh.create_convex_shape()  
		else:
			var sphere := SphereShape3D.new()
			sphere.radius = 10
			col_shape.shape = sphere

# TODO fix full_hats perm hides hair
func adjust_hair_hider(_hat_name, mesh_instance: MeshInstance3D, skeleton:Skeleton3D, is_hair_bald := false):
	var hider_node:BoneAttachment3D = skeleton.get_node("HairHider")
	var hair_node:MeshInstance3D = skeleton.get_node("Hair")
	var hair_material: Material = hair_node.get_active_material(0)
	
	# hide hair if hat is visible and is full hat
	hair_node.visible = !is_hair_bald && !(mesh_instance.visible && full_hats.any(func (hat): return _hat_name == hat))
	if mesh_instance.visible:
		hider_node.show()
		
		# add new hiders
		var base_mesh:MeshInstance3D = hider_node.get_node("Controller/HatHairHider")
		var new_hider_node:Node3D = hider_node.get_node("Controller/NewHiders")
		if new_hider_node.get_child_count() == 0:
			for i in range(100):
				var new_node = base_mesh.duplicate()
				new_node.position.y += i * .1
				new_hider_node.add_child(new_node)
		
		# adjust hiders
		hair_material.transparency = 1
		base_mesh.mesh = mesh_instance.mesh
		for hat_hider:MeshInstance3D in new_hider_node.get_children():
			hat_hider.mesh = mesh_instance.mesh
	else:
		hider_node.hide()
		hair_material.transparency = 0

func set_skeleton_shape_key(value, shape_name:String, skel:Skeleton3D):
	for mesh in skel.get_children():
		if !mesh is MeshInstance3D:
			continue
		if mesh.get_blend_shape_count():
			set_mesh_shape_key(value, shape_name, mesh)
	
	if MobConstants.hip_movers.has(shape_name):
		adjust_hip(skel)

func adjust_hip(skel:Skeleton3D):
	var hip_controller = skel.get_node("Hip/HipContainer")
	var body_mesh: MeshInstance3D = skel.get_node("Body")
	
	var added_amount := 0
	for shape_name in MobConstants.hip_movers:
		var shape_id = (body_mesh.mesh as ArrayMesh)._blend_shape_names.find(shape_name)
		var value = body_mesh.get_blend_shape_value(shape_id)
		var multiplier := 4 if shape_name == MobConstants.hip_movers[0] else 7
		added_amount += value * multiplier
	
	hip_controller.transform.origin.x = 17 + added_amount

func set_mesh_shape_key(value, shape_name:String, mesh:MeshInstance3D):
	var shape_id = mesh.find_blend_shape_by_name(shape_name)
	if shape_id>-1:
		mesh.set_blend_shape_value(shape_id,value)

func set_mesh_color(value:Color, mesh_instance:MeshInstance3D,material_nr:=-1):
	material_nr = material_nr if material_nr>=0 else get_main_material(mesh_instance)
	if mesh_instance.mesh:
		var material:StandardMaterial3D = mesh_instance.material_override
		if material == null:
			material = mesh_instance.mesh.surface_get_material(material_nr)
		
		if material:
			material = material.duplicate()
			material.albedo_color = value
			if mesh_instance.material_override != null:
				mesh_instance.material_override = material
			else:
				mesh_instance.set_surface_override_material(material_nr, material)

# GET MESH DATA
func get_main_material(mesh_instance:MeshInstance3D) -> int:
	if mesh_instance.name =="Eyes":
		return 1
	for mesh_name in main_materials.keys():
		if mesh_instance.mesh.resource_path.find(mesh_name) != -1:
			return main_materials[mesh_name]
	return 0

func get_mesh_color(mesh_instance:MeshInstance3D,material_nr:=-1)-> Color:
	material_nr = material_nr if material_nr>=0 else get_main_material(mesh_instance)
	if mesh_instance.mesh:
		var material = mesh_instance.material_override
		if material == null:
			material = mesh_instance.get_surface_override_material(material_nr)
		if material != null and (material is ShaderMaterial or material is StandardMaterial3D):
			if material is StandardMaterial3D:
				return material.albedo_color
			if material is ShaderMaterial:
				return material.get_shader_parameter("color")
	
	return Color(-1,-1,-1)

func get_mesh_from_skeleton(mesh_name:String, skeleton:Skeleton3D) -> MeshInstance3D:
	return skeleton.get_node(mesh_name) if !MobConstants.hand_names.has(mesh_name) else (func():
		return  skeleton.get_node("Hip" if MobConstants.hand_names[0] == mesh_name else "Back").get_child(0).get_child(0)).call()

# TODO add to caches in Utils
var cached_mesh_shape_names := {} # f.e. "Body": ["Body Mass","Body Shape", ... ]
func get_shape_names_from_mesh(mesh_instance:MeshInstance3D)->Array:
	var mesh_name:String = mesh_instance.name
	if cached_mesh_shape_names.has(mesh_name):
		return cached_mesh_shape_names[mesh_name]
	else:
		return range(0, mesh_instance.mesh.get_blend_shape_count()).map(
				func (i): return mesh_instance.mesh.get_blend_shape_name(i)
			)
