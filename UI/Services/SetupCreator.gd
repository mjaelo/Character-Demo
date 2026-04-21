extends Control
class_name SetupCreator

var padding := UIConstants.PICKER_PADDING
var skeleton: Skeleton3D
var mob_data: MobData
@onready var tab_container := $"TabContainer"

var is_mesh_range_incorrect := func(mesh: MeshInstance3D, vals: Array):
	return !mesh || !vals || vals.size() < 2

func setup():
	for tab_name in UIConstants.menu_data.keys():
		create_tab(UIConstants.menu_data[tab_name], tab_name)

func create_tab(tab_data: Array, tab_name: String):
	var tab := TabBar.new()
	tab.name = tab_name
	
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size = tab.size
	
	var vBox := VBoxContainer.new()
	vBox.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	vBox.size_flags_vertical = Control.SIZE_FILL | Control.SIZE_EXPAND
	
	scroll.add_child(vBox)
	tab.add_child(scroll)
	tab_container.add_child(tab)
	
	for picker_info:MeshPickerInfo in tab_data:
		create_pickers(picker_info, vBox)
	
	var stylebox: Resource = scroll.get_theme_stylebox("panel").duplicate()
	stylebox.content_margin_top = padding
	stylebox.content_margin_bottom = padding
	stylebox.content_margin_left = padding
	stylebox.content_margin_right = padding
	scroll.add_theme_stylebox_override("panel", stylebox)

func create_pickers(picker_info:MeshPickerInfo, vBox: VBoxContainer):
	var mesh_name := picker_info.mesh_name
	var mesh_instance := MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
	
	var mesh_info: MobMeshInfo
	if MobConstants.body_mesh_info.has(mesh_name):
		mesh_info = MobConstants.body_mesh_info[mesh_name]
	elif MobConstants.eq_mesh_info.has(mesh_name):
		mesh_info = MobConstants.eq_mesh_info[mesh_name]
	elif mesh_name == "Head":
		mesh_info = MobConstants.body_mesh_info["Body"]
	else:
		print("Couldnt find mesh ", mesh_name)
	
	var label := Label.new()
	label.text = mesh_name
	vBox.add_child(label)
	
	if mesh_info != null:
		if picker_info.has_mesh_picker:
			create_mesh_picker(vBox, mesh_name, mesh_info, mesh_instance)
		if picker_info.has_color_picker:
			create_color_picker(vBox, mesh_name, mesh_info, mesh_instance)
		if picker_info.has_shape_picker:
			for shape_name: String in picker_info.shape_names:
				create_shape_picker(vBox, mesh_name, mesh_info, mesh_instance, shape_name)
	
	var margin := Control.new()
	margin.custom_minimum_size.y = padding
	vBox.add_child(margin)

func create_mesh_picker(vBox: VBoxContainer, mesh_name: String, mesh_info: MobMeshInfo, mesh_instance: MeshInstance3D) ->SliderPickerComponent:
	var node:SliderPickerComponent = UIConstants.SLIDER_PICKER_SCENE.instantiate()
	node.name = mesh_name
	vBox.add_child(node)
	var file_names = FileUtils.get_file_names(mesh_info.mesh_folder)
	file_names.insert(0, "empty")
	node.init(file_names, mesh_name)
	
	if is_mesh_range_incorrect.call(mesh_instance, file_names):
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_picker_value_changed.bind("Mesh", mesh_instance, mesh_instance.name, mesh_info.mesh_folder)
		)
	return node

func create_color_picker(vBox: VBoxContainer, mesh_name: String, mesh_info: MobMeshInfo, mesh_instance: MeshInstance3D) -> ColorPickerComponent:
	var node:ColorPickerComponent = UIConstants.COLOR_PICKER_SCENE.instantiate()
	node.name = mesh_name + "Color"
	vBox.add_child(node)
	var color_values := UIUtils.get_colors_from_color_range(mesh_info.color_range)
	node.init(color_values, mesh_name + " Color")
	
	if is_mesh_range_incorrect.call(mesh_instance, color_values):
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_picker_value_changed.bind("Color", mesh_instance, mesh_name)
		)
	
	if MobConstants.hair_linked_names.has(mesh_name):
		node.hide()
		var box := CheckBox.new()
		box.text = "Edit " + mesh_name + " Color"
		box.add_theme_font_size_override("font_size", 10)
		box.toggled.connect(_on_show_checkbox_toggled.bind(node, mesh_name))
		vBox.add_child(box)
	return node

func create_shape_picker(vBox: VBoxContainer, mesh_name: String, mesh_info: MobMeshInfo, mesh_instance: MeshInstance3D, shape_name: String)->SliderPickerComponent:
	var node:SliderPickerComponent = UIConstants.SLIDER_PICKER_SCENE.instantiate()
	node.name = shape_name
	vBox.add_child(node)
	var min_r = mesh_info.shape_limits[shape_name][0] if mesh_info.shape_limits else 0
	var max_r = mesh_info.shape_limits[shape_name][1] if mesh_info.shape_limits else 1
	var shape_values = range(min_r * 10, max_r * 10 + 1).map(func(e): return e / 10.0)
	node.init(shape_values, shape_name)
	
	if is_mesh_range_incorrect.call(mesh_instance, shape_values) || mesh_instance.find_blend_shape_by_name(shape_name) < 0:
		print(shape_name, " not found on ", mesh_instance.name)
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_picker_value_changed.bind("Shape", mesh_instance, mesh_instance.name, "", shape_name)
		)
	return node

func _on_picker_value_changed(value, picker_type: String, mesh_instance: MeshInstance3D, mesh_name: String = mesh_instance.name, mesh_folder := "", shape_name := ""):
	if MobConstants.weapon_names.has(mesh_name):
		mesh_name = MobConstants.hand_names[MobConstants.weapon_names.find(mesh_name)]
	var data_type = "equipment_data" if MobConstants.cloth_mesh_names.has(mesh_name) else "body_data"
	var mesh_names: Array = MobConstants["body_mesh_info" if data_type == "body_data" else "eq_mesh_info"].keys()
	var mesh_datas: Array = BodyData.FIELD_NAMES if data_type == "body_data" else EquipmentData.FIELD_NAMES
	var mesh_type = mesh_datas[mesh_names.find(mesh_name)]
	
	if picker_type == "Mesh":
		if mob_data[data_type][mesh_type].mesh_name == value:
			return
		var old_brow_name: String
		if mesh_name == "Accessory":
			old_brow_name = mob_data.body_data.brow_mesh.mesh_name
		mob_data[data_type][mesh_type].mesh_name = value
		if mesh_name == "Accessory":
			mob_data.body_data.brow_mesh.mesh_name = old_brow_name
		MobUtils.set_mesh(value, mesh_instance, mesh_folder)
	elif picker_type == "Color":
		var material_nr = -1 if mesh_name != "Body" else 0
		if mob_data[data_type][mesh_type].mesh_color == value:
			return
		MobUtils.set_mesh_color(value, mesh_instance, material_nr)
		if mesh_name == "Hair":
			for linked_name in MobConstants.hair_linked_names:
				_on_picker_value_changed(value, picker_type, mesh_instance.get_parent().get_node(linked_name))
				get_parent().update_mesh_picker(value, "Hair", linked_name, linked_name + "Color")
	elif picker_type == "Shape":
		var shape_id := MobUtils.get_shape_names_from_mesh(mesh_instance.mesh).find(shape_name)
		var mdata_shapes = mob_data[data_type][mesh_type].mesh_shape
		if float(mdata_shapes[shape_id]) == value:
			return
		mob_data[data_type][mesh_type].mesh_shape[shape_id] = value
		MobUtils.set_skeleton_shape_key(value, shape_name, mesh_instance.get_parent())

func _on_show_checkbox_toggled(toggled_on: bool, node_to_show: Control, mesh_name: String):
	node_to_show.visible = toggled_on
	if !toggled_on:
		var hair_color := MobUtils.get_mesh_color(skeleton.get_node("Hair"))
		_on_picker_value_changed(hair_color, "Color", skeleton.get_node(mesh_name))
		get_parent().update_mesh_picker(hair_color, "Hair", mesh_name, mesh_name + "Color")
