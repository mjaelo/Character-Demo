extends Control

const padding := 10
var skeleton:Skeleton3D
var picker_scene = load("res://UI/utils/ValuePicker.tscn")
# TODO does it even work? already used in ValuePicker
var data_check := func (mesh:MeshInstance3D,ran:Array):
	return !mesh || !ran || ran.size()<2

func setup(menu_data:Dictionary,_skeleton:Skeleton3D):
	skeleton = _skeleton
	for tab_name in menu_data.keys():
		create_tab(menu_data[tab_name], tab_name)

func create_tab(tab_data:Dictionary, tab_name:String):
	# setup tab
	var tab:=TabBar.new()
	tab.name = tab_name
	
	var scroll:=ScrollContainer.new()
	scroll.layout_mode = 1
	scroll.anchors_preset = Control.LayoutPreset.PRESET_FULL_RECT
	scroll.size = tab.size
	
	var vBox := VBoxContainer.new()
	vBox.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	vBox.size_flags_vertical = Control.SIZE_FILL | Control.SIZE_EXPAND
	
	scroll.add_child(vBox)
	tab.add_child(scroll)
	$"../TabContainer".add_child(tab)
	
	# add tab content
	for mesh_name in tab_data.keys():
		create_pickers(tab_data[mesh_name],mesh_name,vBox)
	
	# add tab padding
	var stylebox = scroll.get_theme_stylebox("panel").duplicate()
	stylebox.content_margin_top = padding
	stylebox.content_margin_bottom = padding
	stylebox.content_margin_left = padding
	stylebox.content_margin_right = padding

	scroll.add_theme_stylebox_override("panel", stylebox)

func create_pickers(mesh_data:Array, mesh_name:String, vBox:VBoxContainer):
	var mesh_instance := MobUtils.get_mesh_from_skeleton(mesh_name, skeleton)
	var range := range(0,10)
	
	var mesh_info = {"mesh_folder":"","color_range":{},"shape_names": []}
	if MobConstants.body_mesh_info.has(mesh_name):
		mesh_info = MobConstants.body_mesh_info[mesh_name]
	elif MobConstants.eq_mesh_info.has(mesh_name):
		mesh_info = MobConstants.eq_mesh_info[mesh_name]
	else:
		print("Couldnt find mesh", mesh_name)
	
	# add section mesh title
	var label := Label.new()
	label.text = mesh_name
	vBox.add_child(label)
	
	# Mesh
	if mesh_data[0]:
		create_mesh_picker(vBox,mesh_name,mesh_info,range,mesh_instance)
	
	# Color
	if mesh_data[1]:
		create_color_picker(vBox,mesh_name,mesh_info,range,mesh_instance)
	
	# Shape Keys
	for shape_name:String in mesh_data[2]:
		create_shape_picker(vBox,mesh_name,mesh_info,range,mesh_instance,shape_name)
	
	# bottom margin
	var margin := Control.new()
	margin.custom_minimum_size.y = padding
	vBox.add_child(margin)

func create_mesh_picker(vBox:VBoxContainer, mesh_name:String,mesh_info:Dictionary,range:Array,mesh_instance:MeshInstance3D):
	var node = picker_scene.instantiate()
	node.name = mesh_name
	vBox.add_child(node)
	range = Utils.get_file_names(mesh_info.mesh_folder)
	if !MobConstants.non_empty_names.has(mesh_name):
		range.insert(0,"empty") # add option to hide mesh
	node.init(range, mesh_name)
	
	if data_check.call(mesh_instance,range):
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_picker_value_changed.bind("Mesh", mesh_instance, mesh_info.mesh_folder)
		)
	return node

func create_color_picker(vBox:VBoxContainer, mesh_name:String,mesh_info:Dictionary,range:Array,mesh_instance:MeshInstance3D):
	var node = picker_scene.instantiate()
	node.name = mesh_name + "Color"
	vBox.add_child(node)
	range = mesh_info.color_range.values().map(
		func (minmax:Array): 
			return range(minmax[0]*100, minmax[1]*100).map(
				func (e): return e/100.0))
	node.init(range, mesh_name+" Color", "color")

	if data_check.call(mesh_instance,range):
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_picker_value_changed.bind("Color", mesh_instance)
		)
		
	if MobConstants.hair_linked_names.has(mesh_name):
		node.hide()
		var box := CheckBox.new()
		box.text = "Edit " + mesh_name + " Color"
		box.add_theme_font_size_override("font_size",10)
		box.toggled.connect(_on_show_checkbox_toggled.bind(node,mesh_name))
		vBox.add_child(box)

func create_shape_picker(vBox:VBoxContainer, mesh_name:String,mesh_info:Dictionary,range:Array,mesh_instance:MeshInstance3D,shape_name:String):
	var node = picker_scene.instantiate()
	node.name = shape_name
	vBox.add_child(node)
	var min_r = mesh_info.shape_limits[shape_name][0] if mesh_info.has("shape_limits") else 0
	var max_r = mesh_info.shape_limits[shape_name][1] if mesh_info.has("shape_limits") else 1
	range =  range(min_r*10,max_r*10+1).map(func (e): return e/10.0)
	node.init(range,shape_name)
	
	if data_check.call(mesh_instance,range) || mesh_instance.find_blend_shape_by_name(shape_name) < 0:
		node.disabled = true
	else:
		node.variable_changed.connect(
			_on_picker_value_changed.bind("Shape", mesh_instance, "",shape_name)
		)
	return node

func _on_picker_value_changed(value, picker_type:String, mesh_instance:MeshInstance3D,mesh_folder:="",shape_name:=""):
	var mesh_name:String = mesh_instance.name
	if MobConstants.weapon_names.has(mesh_name):
		mesh_name =  MobConstants.hand_names[MobConstants.weapon_names.find(mesh_name)]
	var data_type = "equipment_data" if $"../".menu_data.Clothes.keys().has(mesh_name) else "body_data"
	var mesh_names:Array = MobConstants["body_mesh_info" if data_type == "body_data" else "eq_mesh_info"].keys()
	var mesh_datas := Utils.get_user_defined_variables($"../".mob_data[data_type])
	var mesh_type = mesh_datas[mesh_names.find(mesh_name)]
	
	if picker_type == "Mesh":
		if $"../".mob_data[data_type][mesh_type].mesh_name == value:
			return
		$"../".mob_data[data_type][mesh_type].mesh_name = value
		var is_bald:bool = false if mesh_type != "Hat" else $"../".mob_data.body_data.hair_data.mesh_name == "empty"
		MobUtils.set_mesh(value, mesh_instance, mesh_folder,is_bald)
	elif picker_type == "Color":
		if $"../".mob_data[data_type][mesh_type].mesh_color == value:
			return
		MobUtils.set_mesh_color(value, mesh_instance)
		if mesh_name == "Hair": # set linked color
			for linked_name in MobConstants.hair_linked_names:
				_on_picker_value_changed(value,picker_type,mesh_instance.get_parent().get_node(linked_name))
				get_parent().update_mesh_picker(value,"Hair",linked_name,linked_name+"Color")
	elif picker_type == "Shape":
		var shape_id = MobUtils.get_shape_names_from_mesh(mesh_instance).find(shape_name)
		if $"../".mob_data[data_type][mesh_type].mesh_shape[shape_id] == value:
			return
		$"../".mob_data[data_type][mesh_type].mesh_shape[shape_id] = value
		MobUtils.set_skeleton_shape_key(value, shape_name, mesh_instance.get_parent())

func _on_show_checkbox_toggled(toggled_on:bool,node_to_show:Control,mesh_name:String):
	node_to_show.visible = toggled_on
	if !toggled_on:
		var hair_color := MobUtils.get_mesh_color(skeleton.get_node("Hair"))
		_on_picker_value_changed(hair_color,"Color",skeleton.get_node(mesh_name))
		get_parent().update_mesh_picker(hair_color,"Hair",mesh_name,mesh_name+"Color")
