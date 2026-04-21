extends Node

# TODO fix after adding skin to clothes
const main_materials := { # TODO () eyes are not here...
	"merchant-top": 2,
	"merchant-hat": 2,
	"guard-bottom": 1,
	"guard-top": 2
}

var full_hats: Array

func _ready() -> void:
	var hat_tag_dict: Dictionary = FileUtils.load_json_from_file(MobConstants.eq_mesh_info.Hat.file_folder+"tag_info.json")
	full_hats = hat_tag_dict.keys().filter(func (key): return hat_tag_dict[key].has("full-hat"))

# SET MESH DATA
func set_mesh(file_name:String, mesh_instance:MeshInstance3D, path:String):
	# "empty" means hide this mesh slot
	if file_name == "empty" || file_name == "":
		mesh_instance.hide()
		# still handle hair hider / sword cases
		if mesh_instance.name == "Hat" || mesh_instance.name == "Hair":
			var skeleton:Skeleton3D = mesh_instance.get_parent()
			adjust_hair_hider(skeleton.get_node("Hat"), skeleton.get_node("Hair"), skeleton)
		return
	
	# set mesh from file
	var file_path = path+file_name+".tres"
	var new_mesh = FileUtils.load_mesh_from_file(file_path)
	if new_mesh:
		var color = get_mesh_color(mesh_instance)
		var shape_names := get_shape_names_from_mesh(mesh_instance.mesh)
		
		mesh_instance.show()
		mesh_instance.mesh = new_mesh
		set_mesh_color(color,mesh_instance)
		
		# resetting shape values to mesh shouldnt be neccesarry
		if get_shape_names_from_mesh(mesh_instance.mesh) != shape_names:
			print(mesh_instance.mesh.resource_path," has wrong shape order")
			var shape_values := range(mesh_instance.get_blend_shape_count()).map(func (id): return mesh_instance.get_blend_shape_value(id))
			for i in shape_names.size():
				var id = mesh_instance.find_blend_shape_by_name(shape_names[i])
				if id >-1:
					mesh_instance.set_blend_shape_value(id, shape_values[i])
	else:
		mesh_instance.hide()
		if file_name != "empty":
			print(file_path," not found")
	
	# handle specific case mashes
	if mesh_instance.name == "Hat" || mesh_instance.name == "Hair": 
		var skeleton:Skeleton3D = mesh_instance.get_parent()
		var hair_node:MeshInstance3D = skeleton.get_node("Hair")
		var hat_node:MeshInstance3D = skeleton.get_node("Hat")
		adjust_hair_hider(hat_node,hair_node, skeleton)
	
	# adjust sword collision shape
	if mesh_instance.name == "Sword":
		var col_shape:CollisionShape3D = mesh_instance.get_node("StaticBody3D/CollisionShape3D")
		if mesh_instance.visible:
			col_shape.shape = mesh_instance.mesh.create_convex_shape()  
		else:
			var sphere := SphereShape3D.new()
			sphere.radius = 10
			col_shape.shape = sphere

# TODO use full_hats tag?
func adjust_hair_hider(hat_mesh: MeshInstance3D, hair_mesh: MeshInstance3D, skeleton:Skeleton3D):
	var hider_node:BoneAttachment3D = skeleton.get_node("HairHider")
	var hair_material: Material = hair_mesh.get_active_material(0)
	var body_data:BodyData = skeleton.get_node("../../../").body_data
	var eq_data:EquipmentData = skeleton.get_node("../../../").equipment_data
	
	# hide hair if hat is visible and is full hat
	var is_hair_bald:bool = body_data.hair_mesh.mesh_file == "empty"
	hair_mesh.visible = !is_hair_bald && !(hat_mesh.visible && full_hats.any(func (hat): return eq_data.hat_mesh.mesh_file == hat))
	if hat_mesh.visible && hair_mesh.visible:
		hider_node.show()
		
		# add new hiders
		var base_mesh:MeshInstance3D = hider_node.get_node("Controller/HatHairHider")
		var new_hider_node:Node3D = hider_node.get_node("Controller/NewHiders")
		
		# adjust hiders
		hair_material.transparency = 1
		hair_material.render_priority = -1
		base_mesh.mesh = hat_mesh.mesh
		base_mesh.get_active_material(0).render_priority = 2
		for hat_hider:MeshInstance3D in new_hider_node.get_children():
			hat_hider.mesh = hat_mesh.mesh
		
		if new_hider_node.get_child_count() == 0:
			for i in range(100):
				var new_node = base_mesh.duplicate()
				new_node.position.y += i * .1
				new_hider_node.add_child(new_node)
	else:
		hider_node.hide()
		hair_material.transparency = 0

func set_skeleton_shape_key(value:float, shape_name:String, skel:Skeleton3D):
	for mesh in skel.get_children():
		if !mesh is MeshInstance3D:
			continue
		if mesh.get_blend_shape_count():
			set_mesh_shape_key(value, shape_name, mesh)
	
	if MobConstants.hip_movers.has(shape_name):
		adjust_hip(skel)

func adjust_hip(skel:Skeleton3D):
	var hip_controller = skel.get_node("Hip/HipContainer")
	var body_mesh: MeshInstance3D = skel.get_node("Top")
	
	var added_amount := 0
	for shape_name in MobConstants.hip_movers:
		var shape_id = (body_mesh.mesh as ArrayMesh)._blend_shape_names.find(shape_name)
		var value = body_mesh.get_blend_shape_value(shape_id)
		var multiplier := 4 if shape_name == MobConstants.hip_movers[0] else 7
		added_amount += value * multiplier
	
	hip_controller.transform.origin.x = 17 + added_amount

func set_mesh_shape_key(value:float, shape_name:String, mesh:MeshInstance3D):
	var shape_id = mesh.find_blend_shape_by_name(shape_name)
	if shape_id>-1:
		mesh.set_blend_shape_value(shape_id,value)

func set_mesh_color(value:Color, mesh_instance:MeshInstance3D,material_nr:=-1):
	material_nr = material_nr if material_nr>=0 else get_main_material(mesh_instance)
	if mesh_instance.mesh:
		if material_nr >= mesh_instance.mesh.get_surface_count():
			material_nr = 0
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
	
		if mesh_instance.name == "Body" && material_nr == 0:
			for n_name in MobConstants.meshes_with_skin:
				if n_name != mesh_instance.name:
					set_mesh_color(value, mesh_instance.get_parent().get_node(n_name),material_nr)

# GET MESH DATA
func get_main_material(mesh_instance:MeshInstance3D) -> int:
	if mesh_instance.name =="Eyes":
		return 1
	for mesh_name in main_materials.keys():
		if mesh_instance.mesh.resource_path.find(mesh_name) != -1:
			return main_materials[mesh_name]
	if MobConstants.meshes_with_skin.has(mesh_instance.name):
		return 1
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
	
	return Color(-1, -1, -1)

func get_mesh_from_skeleton(mesh_name:String, skeleton:Skeleton3D) -> MeshInstance3D:
	if MobConstants.hand_names.has(mesh_name):
		return skeleton.get_node("Hip" if MobConstants.hand_names[0] == mesh_name else "Back").get_child(0).get_child(0)
	else:
		return skeleton.get_node(mesh_name)  
		
# TODO add to caches in Utils
var cached_mesh_shape_names := {} # f.e. "Top": ["Body Mass","Body Shape", ... ]
func get_shape_names_from_mesh(mesh_array:ArrayMesh)->Array:
	var mesh_name:String = mesh_array.resource_path
	if !cached_mesh_shape_names.has(mesh_name):
		cached_mesh_shape_names[mesh_name] = range(0, mesh_array.get_blend_shape_count()).map(
			func (i): return mesh_array.get_blend_shape_name(i)
		)
	return cached_mesh_shape_names[mesh_name]


func spawn_opponent(parent: Node = null):
	var scene = load(MobConstants.MOB_SCENE_PATH)
	for x in range(-5, 5):
		var mob: Mob = scene.instantiate()
		mob.transform.origin += Vector3(x * 3, 0, 5)
		var race = MobConstants.MobRaces.values().pick_random()
		var type := MobConstants.MobTypes.Civilian
		MobSetter.set_mob_data_to_mob(
			MobGetter.get_random_mob_data(mob.get_node("body/Armature/Skeleton3D"), race, type),
			mob
		)
		var target = parent if parent else get_tree().current_scene
		target.add_child(mob)

func toggle_player_control(has_control:bool, mob:Player):
	mob.set_process_unhandled_input(has_control)
	mob.set_physics_process(has_control)
