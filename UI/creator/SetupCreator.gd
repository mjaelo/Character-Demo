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
	# TODO () also used similarly in BodyGenerator, preset_tab and Creator.
	var mesh_instance = skeleton.get_node(mesh_name)
	if MobConstants.hand_names.has(mesh_name): # get embedded mesh TODO () Code duplicate with B Gen
		mesh_instance = mesh_instance.get_parent().get_node("Hip" if MobConstants.hand_names[0] == mesh_name else "Back").get_child(0).get_child(0)
	var range := range(0,10)
	
	var mesh_info = {"mesh_folder":"","color_range":{},"shape_names": []}
	if BodyGenerator.body_mesh_info.has(mesh_name):
		mesh_info = BodyGenerator.body_mesh_info[mesh_name]
	elif BodyGenerator.eq_mesh_info.has(mesh_name):
		mesh_info = BodyGenerator.eq_mesh_info[mesh_name]
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
			MobUtils.set_mesh.bind(mesh_instance, mesh_info.mesh_folder))
		if mesh_name == "Hat":
			node.variable_changed.connect(
				MobUtils.adjust_hair_hider.bind(mesh_instance,skeleton))
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
		node.variable_changed.connect(MobUtils.set_mesh_color.bind(mesh_instance))
	
	# set linked hair color
	if mesh_instance == skeleton.get_node("Hair"):
		node.variable_changed.connect(
			get_parent().update_linked_colors.bind("Hair",MobConstants.hair_linked_names))
	if MobConstants.hair_linked_names.has(mesh_name):
		node.hide()
		var box := CheckBox.new()
		box.text = "Edit " + mesh_name + " Color"
		box.add_theme_font_size_override("font_size",10)
		box.toggled.connect(get_parent()._on_show_checkbox_toggled.bind(node,mesh_name))
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
			MobUtils.set_skeleton_shape_key.bind(shape_name, skeleton))
	return node
