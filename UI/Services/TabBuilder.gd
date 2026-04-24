extends Resource
class_name TabBuilder

var padding := UIConstants.PICKER_PADDING
var skeleton: Skeleton3D
var mob_data: MobData

var is_mesh_range_incorrect := func(mesh: MeshInstance3D, vals: Array):
	return !mesh || !vals || vals.size() < 2

func _init(_skeleton: Skeleton3D, _mob_data: MobData):
	skeleton = _skeleton
	mob_data = _mob_data

# SETUP TAB PICKERS
func create_tab(mesh_picker_infos: Array, tab_name: String) -> TabBar:
	var tab := TabBar.new()
	tab.name = tab_name
	
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
#	scroll.size = tab.size
	
	var vBox := VBoxContainer.new()
	vBox.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	vBox.size_flags_vertical = Control.SIZE_FILL | Control.SIZE_EXPAND
	
	scroll.add_child(vBox)
	tab.add_child(scroll)
	
	for picker_info:MeshPickerInfo in mesh_picker_infos:
		create_pickers_for_mesh(picker_info, vBox)
	
	var stylebox: Resource = scroll.get_theme_stylebox("panel").duplicate()
	stylebox.content_margin_top = padding
	stylebox.content_margin_bottom = padding
	stylebox.content_margin_left = padding
	stylebox.content_margin_right = padding
	scroll.add_theme_stylebox_override("panel", stylebox)
	
	return tab

func create_pickers_for_mesh(picker_info:MeshPickerInfo, vBox: VBoxContainer):
	var mesh_name := picker_info.mesh_name
	var mesh_instance := MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
	
	var mesh_info: MobMeshInfo
	if MobConstants.BODY_MESHES_INFO.has(mesh_name):
		mesh_info = MobConstants.BODY_MESHES_INFO[mesh_name]
	elif MobConstants.EQ_MESHES_INFO.has(mesh_name):
		mesh_info = MobConstants.EQ_MESHES_INFO[mesh_name]
	elif mesh_name == "Head":
		mesh_info = MobConstants.BODY_MESHES_INFO["Body"]
	else:
		print("Couldnt find mesh ", mesh_name)
	
	var label := Label.new()
	label.text = mesh_name
	vBox.add_child(label)
	
	if mesh_info != null:
		if picker_info.has_file_picker:
			var options := FileUtils.get_file_names(mesh_info.file_folder)
			var picker := create_mesh_picker(mesh_name, options, mesh_instance,mesh_info.file_folder)
			vBox.add_child(picker)
		if picker_info.has_color_picker:
			var picker := create_color_picker(mesh_name, mesh_info.colors, mesh_instance)
			vBox.add_child(picker)
		if picker_info.has_shape_picker:
			for shape_name: String in MobConstants.BodyMeshShapes[mesh_name]:
				var options: Array[float] = mesh_info.shapes[shape_name]
				var picker := create_shape_picker(mesh_name, options, mesh_instance, shape_name)
				vBox.add_child(picker)
	
	var margin := Control.new()
	margin.custom_minimum_size.y = padding
	vBox.add_child(margin)

func create_mesh_picker(mesh_name: String, file_names: Array, mesh_instance: MeshInstance3D, file_folder: String) ->SliderPickerComponent:
	var node:SliderPickerComponent = UIConstants.SLIDER_PICKER_SCENE.instantiate()
	node.name = mesh_name
	file_names.insert(0, "empty")
	node.init(file_names, mesh_name)
	
	if is_mesh_range_incorrect.call(mesh_instance, file_names):
		print(mesh_name, " mesh range is incorrect")
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_mesh_picker_value_changed.bind(mesh_instance,  mesh_name, file_folder)
		)
	return node

func create_color_picker(mesh_name: String, color_values: Array, mesh_instance: MeshInstance3D) -> ColorPickerComponent:
	var node:ColorPickerComponent = UIConstants.COLOR_PICKER_SCENE.instantiate()
	node.name = mesh_name + "Color"
	node.init(color_values, mesh_name + " Color")
	
	if is_mesh_range_incorrect.call(mesh_instance, color_values):
		print(mesh_name, " color range is incorrect")
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_color_picker_value_changed.bind(mesh_instance, mesh_name)
		)
	return node

func create_shape_picker(mesh_name: String, shape_values: Array, mesh_instance: MeshInstance3D, shape_name: String)->SliderPickerComponent:
	var node:SliderPickerComponent = UIConstants.SLIDER_PICKER_SCENE.instantiate()
	node.name = shape_name
	node.init(shape_values, shape_name)
	
	if is_mesh_range_incorrect.call(mesh_instance, shape_values) || mesh_instance.find_blend_shape_by_name(shape_name) < 0:
		print(shape_name, " not found on ", mesh_name)
		node.disabled = true
	else:
		var shape_id := MobUtils.get_shape_names_from_mesh(mesh_instance.mesh).find(shape_name)
		node.variable_changed.connect(
			_on_shape_picker_value_changed.bind(mesh_instance, mesh_name, shape_id, shape_name)
		)
	return node

# PICKER CALLBACKS update mob_data and mob body
func _on_mesh_picker_value_changed(value:String, mesh_instance: MeshInstance3D, mesh_name: String = mesh_instance.name, file_folder := ""):	
	if MobConstants.BODY_MESHES_INFO.has(mesh_name):
		var field_name:String= MobConstants.BODY_MESHES_INFO[mesh_name].field_name
		mob_data.body_data[field_name].mesh_file = value
	elif MobConstants.EQ_MESHES_INFO.has(mesh_name):
		var field_name:String= MobConstants.EQ_MESHES_INFO[mesh_name].field_name
		mob_data.equipment_data[field_name].mesh_file = value
	else:
		print("Mesh picker value changed for unknown mesh: ", mesh_name)
	
	MobUtils.set_mesh(value, mesh_instance, file_folder)

func _on_color_picker_value_changed(value:Color, mesh_instance: MeshInstance3D, mesh_name: String = mesh_instance.name):
	if MobConstants.BODY_MESHES_INFO.has(mesh_name):
		var field_name:String= MobConstants.BODY_MESHES_INFO[mesh_name].field_name
		mob_data.body_data[field_name].mesh_color = value
	elif MobConstants.EQ_MESHES_INFO.has(mesh_name):
		var field_name:String= MobConstants.EQ_MESHES_INFO[mesh_name].field_name
		mob_data.equipment_data[field_name].mesh_color = value
	else:
		print("Color picker value changed for unknown mesh: ", mesh_name)
	
	var material_nr := -1 if mesh_name != "Body" else 0
	MobUtils.set_mesh_color(value, mesh_instance, material_nr)
	
	# Propagate hair color to linked meshes (Brows, Beard) TODO duplicated by TabBuilder MobGetter and MobAdjuster
	if mesh_name == "Hair":
		MobUtils.propagade_hair_color(mob_data.body_data, skeleton)

func _on_shape_picker_value_changed(value:float, mesh_instance: MeshInstance3D, mesh_name: String = mesh_instance.name, shape_id := 0, shape_name := ""):
	if MobConstants.BODY_MESHES_INFO.has(mesh_name):
		var field_name:String= MobConstants.BODY_MESHES_INFO[mesh_name].field_name
		mob_data.body_data[field_name].mesh_shape[shape_id] = value
	elif MobConstants.EQ_MESHES_INFO.has(mesh_name):
		var field_name:String = MobConstants.EQ_MESHES_INFO[mesh_name].field_name
		mob_data.equipment_data[field_name].mesh_shape[shape_id] = value
	else:
		print("Shape picker value changed for unknown mesh: ", mesh_name)
	
	MobUtils.set_skeleton_shape_key(value, shape_name, mesh_instance.get_parent())
