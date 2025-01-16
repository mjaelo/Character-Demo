extends Node

const main_materials := { # TODO () theres no eyes here. so how does that work?
	"merchant-top": 2,
	"merchant-hat": 2,
	"guard-bottom": 1,
	"guard-top": 2
}
const full_hats := ["guard-hat"] # TODO () use tag full-hat instead. Also, when this tag detected, hide whole hair?

func set_mesh(file_name:String, mesh_instance:MeshInstance3D, path:String):
	var file_path = path+file_name+".tres"
	
	if file_name == "empty":
		mesh_instance.hide()
	else:
		var new_mesh:ArrayMesh = Utils.load_mesh(file_path)
		if new_mesh:
			var color = get_mesh_color(mesh_instance)
			mesh_instance.show()
			mesh_instance.mesh = new_mesh
			set_mesh_color(color,mesh_instance)
			
			if mesh_instance.name == "Hat": 
				MobUtils.adjust_hair_hider(file_name,mesh_instance,mesh_instance.get_parent())
		else:
			mesh_instance.hide()
			print(file_path," not found")
	
	# adjust sword collision shape
	if mesh_instance.name == "Sword":
		var col_shape:CollisionShape3D = mesh_instance.get_node("StaticBody3D/CollisionShape3D")
		if mesh_instance.visible:
			col_shape.shape = mesh_instance.mesh.create_convex_shape()  
		else:
			var sphere := SphereShape3D.new()
			sphere.radius = 10
			col_shape.shape = sphere

func set_skeleton_shape_key(value, shape_name:String, skel:Skeleton3D):
	for mesh in skel.get_children():
		if !mesh is MeshInstance3D:
			continue
		if mesh.get_blend_shape_count():
			set_mesh_shape_key(value, shape_name, mesh)
	
	if MobConstants.hip_movers.has(shape_name):
		adjust_hip(skel)

func set_mesh_shape_key(value, shape_name:String, mesh:MeshInstance3D):
	var shape_id = mesh.find_blend_shape_by_name(shape_name)
	if shape_id>-1:
		mesh.set_blend_shape_value(shape_id,value)

func set_mesh_color(value:Color, mesh_instance:MeshInstance3D):
	if mesh_instance.mesh:
		var material = mesh_instance.material_override
		if material == null:
			material = mesh_instance.mesh.surface_get_material(get_main_material(mesh_instance))
		if material != null and (material is ShaderMaterial or material is StandardMaterial3D):
			if material is StandardMaterial3D:
				material.albedo_color = value
			if material is ShaderMaterial:
				material.set_shader_parameter("color", value)

func get_main_material(mesh_instance:MeshInstance3D) -> int:
	if mesh_instance.name =="Eyes":
		return 1
	for mesh_name in main_materials.keys():
		if mesh_instance.mesh.resource_path.find(mesh_name) != -1:
			return main_materials[mesh_name]
	return 0

func get_mesh_color(mesh_instance:MeshInstance3D)-> Color:
	if mesh_instance.mesh:
		var material = mesh_instance.material_override
		if material == null:
			material = mesh_instance.mesh.surface_get_material(get_main_material(mesh_instance))
		if material != null and (material is ShaderMaterial or material is StandardMaterial3D):
			if material is StandardMaterial3D:
				return material.albedo_color
			if material is ShaderMaterial:
				return material.get_shader_parameter("color")
	
	return Color(0,0,0)

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

func adjust_hair_hider(_hat_name, mesh_instance: MeshInstance3D, skeleton:Skeleton3D):
	var hider_node:BoneAttachment3D = skeleton.get_node("HairHider")
	var hair_node:MeshInstance3D = skeleton.get_node("Hair")
	var hair_material: Material = hair_node.get_active_material(0)
	
	# hide hair if hat is visible and is full hat
	hair_node.visible = !(mesh_instance.visible && full_hats.any(func (hat): return mesh_instance.mesh.resource_path.find(hat) != -1))
	if mesh_instance.visible && hair_node.visible:
		hider_node.show()
		
		# add new hiders
		var base_mesh:MeshInstance3D = hider_node.get_node("Controller/HatHairHider")
		var new_hider_node:Node3D = hider_node.get_node("Controller/NewHiders")
		if new_hider_node.get_child_count() == 0:
			for i in range(100):
				var new_node = base_mesh.duplicate()
				new_node.position.y += i * .1
				new_hider_node.add_child(new_node)
		else:
			hair_material.transparency = 1
			base_mesh.mesh = mesh_instance.mesh
			for hat_hider:MeshInstance3D in new_hider_node.get_children():
				hat_hider.mesh = mesh_instance.mesh
	else:
		hider_node.hide()
		hair_material.transparency = 0
