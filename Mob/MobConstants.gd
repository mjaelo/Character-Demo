extends Node
#TODO add more probabilities: nonbin prob, hat prob
# UTILS FOR CONST
var other_races := func (race_id:int)->Array: return MobRaces.keys().filter(func (race): return race != MobRaces.keys()[race_id])
var race_cam_height := func (race_id:int)->float: return race_cam_heights.default if !race_cam_heights.has(race_id) else race_cam_heights[race_id]
var get_random_gender := func ()->int: return [Gender.Male,Gender.Female].pick_random() if randf()> variation_chance else Gender.NonBin

# Expands "BodyBulk"/"EquipmentBulk" keys in a dict to individual mesh names.
# Specific overrides take priority over bulk entries.
static func _expand_bulk(dict: Dictionary) -> Dictionary:
	var result := dict.duplicate()
	if result.has("BodyBulk"):
		var bulk_val = result["BodyBulk"]
		result.erase("BodyBulk")
		for mesh_name in BODY_BULK_NAMES:
			if !result.has(mesh_name):
				result[mesh_name] = bulk_val
	if result.has("EquipmentBulk"):
		var bulk_val = result["EquipmentBulk"]
		result.erase("EquipmentBulk")
		for mesh_name in EQUIPMENT_BULK_NAMES:
			if !result.has(mesh_name):
				result[mesh_name] = bulk_val
	return result

# Bulk expansion: maps bulk keywords to actual mesh names
const BODY_BULK_NAMES := ["Body", "Head", "Eyes", "Eyelashes", "Hair", "Beard", "Brows"]
const EQUIPMENT_BULK_NAMES := ["Top", "Bottom", "Shoes", "Hat", "Right Hand", "Left Hand", "Accessory"]

# CONST
const MOB_SCENE_PATH := "res://Mob/Scenes/Mob/Mob.tscn"

const meshes_with_skin := ["Top","Bottom","Head"]
const hand_names := ["Right Hand","Left Hand"]
const weapon_names := ["Sword","Shield"]
const non_empty_names := ["Top","Bottom","Shoes","Eyelashes"]
const hair_linked_names := ["Brows","Beard"]
const half_empty_names := ["Hat", "Beard"]
const gendered_mesh_names := ["Beard","Eyelashes"]
const hip_movers := ["Body Shape", "Body Mass"]
const meshes_with_shapes := ["Body","Brows","Head"] # meshes with shape keys
const cloth_mesh_names := ["Top","Bottom","Shoes","Hat","Left Hand","Right Hand"]
# TODO () use tag_list for validation of tags.
var known_tags := ["masculine","feminine", MobTypes.keys(), MobRaces.keys(), "full-hat"] 

# Colors
const Color_Statue_Grey := Color(.3, .3, .3, 0)
var hair_color_ranges := ColorRangeInfo.new(Vector2(0,.2),Vector2(.1,.4),Vector2(0,.7))
var clothes_color_ranges := ColorRangeInfo.new(Vector2(0.0, .27), Vector2(0.0, .3),  Vector2(0.2, .6))
var eyes_color_ranges := ColorRangeInfo.new(Vector2(0.1, 0.6),Vector2(0.2, 0.5),  Vector2(0.3, 0.8))
var skin_color_ranges := ColorRangeInfo.new(Vector2(0.01, 0.08),  Vector2(0.2, 0.3),  Vector2(0.3, 0.95))
var demon_skin_colors := UIUtils.get_colors_from_color_range(UIUtils.get_color_range_from_color(Color.DARK_RED))
var demon_clothes_colors := UIUtils.get_colors_from_color_range(UIUtils.get_color_range_from_color(Color.BLACK))
var statue_colors := UIUtils.get_colors_from_color_range(UIUtils.get_color_range_from_color(Color_Statue_Grey))
var ogre_colors := UIUtils.get_colors_from_color_range(UIUtils.get_color_range_from_color(Color.DARK_OLIVE_GREEN))
var spirit_eyes_colors := UIUtils.get_colors_from_color_range(UIUtils.get_color_range_from_color(Color(10, 10, 10, 1.0)))
var spirit_skin_colors := UIUtils.get_colors_from_color_range(ColorRangeInfo.new(Vector2(0.1, 0.6),Vector2(0.2, 0.5),  Vector2(0.3, 0.8),Vector2(5,5)))
# ENUMS
enum MobTypes {Civilian, Guard, Noble, Merchant, Farmer}
enum MobRaces {Human,Skeleton,Ogre,Spirit,Demon,Statue}
enum Gender {Male,NonBin,Female}

# Meshes and their shapes TODO validate shapes upon mesh file load
enum BodyMeshes {
		Body, Top, Bottom, Shoes,  LeftHand, RightHand, # Body
		Hat, Hair,  Head, Brows, Eyelashes, Beard, Eyes # Head
}
const BodyMeshShapes := {
	# Body
	"Body": ["Body Shape", "Body Mass", "Body Muscles"],
	"Top": ["Body Shape", "Body Mass", "Body Muscles"],
	"Bottom": ["Body Shape", "Body Mass", "Body Muscles"],
	"Shoes": [],
	"LeftHand": [],
	"RightHand": [],
	
	# Head
	"Hat": [],
	"Hair": [],
	"Head": ["Lips Width", "Lips Thickness", "Lip Corner", "Jaw Shape", "Face Length","Eye Lower Lid Height", "Eye Upper Lid Height","Eye Edge Height"],
	"Brows": ["Brow Thickness","Brow Inner Height","Brow Outer Height"],
	"Eyelashes": ["Eye Lower Lid Height", "Eye Upper Lid Height","Eye Edge Height"],
	"Beard": ["Jaw Shape", "Face Length"],
	"Eyes": []
}

# TODO add separate probabilities for non binary, hat*
const variation_chance := 0.1 # chance for non normative element.
const mob_names := {
	Gender.NonBin: ["Alex", "Sam", "Think", "Hard", "About", "Your Life Choices"],
	Gender.Male: ["Jeff", "Hanz", "Louis", "Robert","Clyde","Rupert","Steve"], 
	Gender.Female: ["Anabelle", "Eve", "Penny", "Cleo","Sue"], 
}
# for adjusting mob model in a way not covered by body and eq data TODO add shape key override?
const race_action_dict := {
	MobRaces.Human:{},
	MobRaces.Skeleton:{"show_monster_body":true},
	MobRaces.Spirit:{"scale": .75,"eye_whites":Color(100, 100, 100, 1.0),"eye_pupil":Color(100, 100, 100, 1.0)},
	MobRaces.Ogre:{"scale": 1.5,"eye_whites":Color.ORANGE},
	MobRaces.Demon:{"eye_whites":Color.BLACK},
	MobRaces.Statue:{},
}
const race_cam_heights := {
	"default": 6.7,
	MobRaces.Ogre: 10,
	MobRaces.Spirit: 5
}

# norms CONST
enum NormType {Tag, Mesh, Color, Shape}

var gender_norms := {
	Gender.Male: [
		NormData.new(NormType.Tag,["feminine"],true),
		NormData.new(NormType.Shape, {"Body":{0: [0.0]}},false,true), #"Body Shape" enforce,
		NormData.new(NormType.Shape, {"Body":{8: [-1.0]},"Brows":{0: [1.0]}})# "Lips Width" "Brow Thickness")
	],
	Gender.NonBin: [],
	Gender.Female: [
		NormData.new(NormType.Tag,["masculine"],true),
		NormData.new(NormType.Mesh,{"Beard":"empty"},false,true),
		NormData.new(NormType.Mesh,{"Hair":"empty"}, true,true),
		NormData.new(NormType.Shape,{"Body":{0: [0.5], 8: [1.0]},"Brows":{0: [0.0]}}),#"Body Shape","Lips Width", "Brow Thickness"
	]
}

var type_norms := {
	MobTypes.Civilian : [NormData.new(NormType.Tag,MobTypes.keys(),true)],
	MobTypes.Guard : [NormData.new(NormType.Tag,["Guard"])],
	MobTypes.Noble : [NormData.new(NormType.Tag,["Noble"])],
	MobTypes.Merchant : [NormData.new(NormType.Tag,["Merchant"])],
	MobTypes.Farmer : [NormData.new(NormType.Tag,["Farmer"])]
}

var race_norms := {
	MobRaces.Human: [
		NormData.new(NormType.Tag, other_races.call(MobRaces.Human),true,true),
		NormData.new(NormType.Mesh, {"Accessory": "empty"},false,true),
		NormData.new(NormType.Shape, {"Body": {1: [0.0]}}) # "Body Mass"
	],
	MobRaces.Demon: [
		NormData.new(NormType.Tag, other_races.call(MobRaces.Demon),true, true),
		NormData.new(NormType.Color, _expand_bulk({"Top": demon_skin_colors, "EquipmentBulk":demon_clothes_colors})),
		NormData.new(NormType.Shape,{"Body": {1: [0.0]}}) # "Body Mass"
	],
	MobRaces.Ogre: [
		NormData.new(NormType.Tag, other_races.call(MobRaces.Ogre),true, true),
		NormData.new(NormType.Mesh, {"Hair":"empty","Eyelashes":"empty","Beard":"empty","Brows":"empty","Shoes":"empty"}),
		NormData.new(NormType.Color, {"Top":ogre_colors}),
		NormData.new(NormType.Shape,{"Body": {1: [1.0]}}),#"Body Mass"
	],
	MobRaces.Statue: [
		NormData.new(NormType.Tag, other_races.call(MobRaces.Statue),true, true),
		NormData.new(NormType.Mesh, {"Hat":"empty","Accessory": "empty"}),
		NormData.new(NormType.Color, _expand_bulk({"EquipmentBulk":statue_colors,"BodyBulk":statue_colors})),
		NormData.new(NormType.Shape,{"Body": {1: [0.0]}})#"Body Mass"
	],
	MobRaces.Spirit: [
		NormData.new(NormType.Tag, other_races.call(MobRaces.Spirit),true, true),
		NormData.new(NormType.Mesh, _expand_bulk({"Hair":"empty","Eyelashes":"empty","Beard":"empty","Brows":"empty","EquipmentBulk":"empty","Accessory": "empty"}),false,true),
		NormData.new(NormType.Color,{"Eyes": spirit_eyes_colors,"Top": spirit_skin_colors}),
		NormData.new(NormType.Shape,{"Body": {1: [0.0]}}),#"Body Mass"
	],
	MobRaces.Skeleton: [
		NormData.new(NormType.Tag, other_races.call(MobRaces.Skeleton),true, true),
		NormData.new(NormType.Mesh, _expand_bulk({"EquipmentBulk":"empty", "BodyBulk":"empty"}))
	]
}

# TODO () shape names from mesh / some other place. use shape_id as key instead?
# TODO How to handle body and top separate colors?
var body_mesh_info := {
	"Body": MobMeshInfo.new("", skin_color_ranges, {"Body Shape": Vector2(0, 1), "Body Mass": Vector2(-0.5, 1), "Body Muscles": Vector2(-0.5, 1)}),
	"Head": MobMeshInfo.new("", null, {
		"Lips Width": Vector2(-1, 1), "Lips Thickness": Vector2(-1, 1), "Lip Corner": Vector2(-1, 1), "Jaw Shape": Vector2(-1, 1), "Face Length": Vector2(-1, 1),
		"Eye Lower Lid Height": Vector2(-1, 1), "Eye Upper Lid Height": Vector2(-1, 1), "Eye Edge Height": Vector2(-1, 1)
	}),
	"Eyes": MobMeshInfo.new("", eyes_color_ranges),
	"Eyelashes": MobMeshInfo.new("res://Assets/Mob/face/lashes/"),
	"Hair": MobMeshInfo.new("res://Assets/Mob/hair/", hair_color_ranges),
	"Beard": MobMeshInfo.new("res://Assets/Mob/face/beard/"),
	"Brows": MobMeshInfo.new("", null, {"Brow Thickness": Vector2(0, 1), "Brow Inner Height": Vector2(0, 1), "Brow Outer Height": Vector2(0, 1)})
}

var eq_mesh_info := {
	"Top": MobMeshInfo.new("res://Assets/Mob/top/", clothes_color_ranges),
	"Bottom": MobMeshInfo.new("res://Assets/Mob/bottom/", clothes_color_ranges),
	"Shoes": MobMeshInfo.new("res://Assets/Mob/shoes/", clothes_color_ranges),
	"Hat": MobMeshInfo.new("res://Assets/Mob/hat/", clothes_color_ranges),
	"Right Hand": MobMeshInfo.new("res://Assets/Mob/r_hand/"),
	"Left Hand": MobMeshInfo.new("res://Assets/Mob/l_hand/"),
	"Accessory": MobMeshInfo.new("res://Assets/Mob/accessories/"),
}
