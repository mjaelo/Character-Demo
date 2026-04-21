extends Node
#TODO add more probabilities: nonbin prob, hat prob
# UTILS FOR CONST
var other_races := func (race_id:int)->Array: return MobRaces.keys().filter(func (race): return race != MobRaces.keys()[race_id])
var race_cam_height := func (race_id:int)->float: return race_cam_heights.default if !race_cam_heights.has(race_id) else race_cam_heights[race_id]
var get_random_gender := func ()->int: return [Gender.Male,Gender.Female].pick_random() if randf()> variation_chance else Gender.NonBin
# TODO add range converter
# ENUMS
enum MobTypes {Civilian, Guard, Noble, Merchant, Farmer}
enum MobRaces {Human,Skeleton,Ogre,Spirit,Demon,Statue}
enum Gender {Male,NonBin,Female}
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
const shape_control_meshes := ["Body","Brows","Head"] # meshes with shape keys
const cloth_mesh_names := ["Top","Bottom","Shoes","Hat","Left Hand","Right Hand"]

# Colors
const Color_Statue_Grey := Color(.3, .3, .3, 0)
var hair_color_ranges := ColorRangeInfo.new(Vector2(0,.2),Vector2(.1,.4),Vector2(0,.7))
var clothes_color_ranges := ColorRangeInfo.new(Vector2(0.0, .27), Vector2(0.0, .3),  Vector2(0.2, .6))
var eyes_color_ranges := ColorRangeInfo.new(Vector2(0.1, 0.6),Vector2(0.2, 0.5),  Vector2(0.3, 0.8))
var skin_color_ranges := ColorRangeInfo.new(Vector2(0.01, 0.08),  Vector2(0.2, 0.3),  Vector2(0.3, 0.95))
var demon_skin_color_range := UIUtils.get_color_range_from_color(Color.DARK_RED)
var demon_clothes_color_range := UIUtils.get_color_range_from_color(Color.BLACK)
var statue_color_range := UIUtils.get_color_range_from_color(Color_Statue_Grey)
var ogre_color_range := UIUtils.get_color_range_from_color(Color.DARK_OLIVE_GREEN)
var spirit_eyes_color_range := UIUtils.get_color_range_from_color(Color(10, 10, 10, 1.0))
var spirit_skin_color_range := ColorRangeInfo.new(Vector2(0.1, 0.6),Vector2(0.2, 0.5),  Vector2(0.3, 0.8),Vector2(5,5))

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

# VAR CONST
# TODO () use tag_list for validation of tags.
var known_tags := ["masculine","feminine", MobTypes.keys(), MobRaces.keys(), "full-hat"] 
var gender_norms := {
	Gender.Male: MeshNormData.new(
		[],["feminine"],
		{},{},
		{},{},
		{"Body":{0: 0, 8: -1},"Brows":{0: 1}},{},#"Body Shape","Lips Width" "Brow Thickness"
		{"shape":{"Body": [0]}}  #"enforce": ["Body Shape"]
		),
	Gender.NonBin: MeshNormData.new(),
	Gender.Female: MeshNormData.new(
		[],["masculine"],
		{"Beard":"empty"},{"Hair":"empty"},
		{},{}, 
		{"Body":{0: .5, 8: 1},"Brows":{0: 0}},{},#"Body Shape",TODO "Lips Width", "Brow Thickness"
		{"mesh_name":["Beard","Hair"]}# enforce
	)
}

var type_norms := {
	MobTypes.Civilian : MeshNormData.new([],MobTypes.keys()),
	MobTypes.Guard : MeshNormData.new(["Guard"]),
	MobTypes.Noble : MeshNormData.new(["Noble"]),
	MobTypes.Merchant : MeshNormData.new(["Merchant"]),
	MobTypes.Farmer : MeshNormData.new(["Farmer"])
}

var race_norms := {
	MobRaces.Human: MeshNormData.new(
		[], other_races.call(MobRaces.Human),
		{"Accessory": "empty","Top":"tshirt","Bottom":"pants"},{},
		{},{},
		{"Body": {1: 0}},{}, # "Body Mass"
		{"mesh_name": ["Accessory"],"tags":other_races.call(MobRaces.Human)}
	),
	MobRaces.Demon: MeshNormData.new(
		["Demon"], other_races.call(MobRaces.Demon),
		{},{},
		{
		"Top": demon_skin_color_range,
		"EquipmentBulk":demon_clothes_color_range,
		},{},
		{"Body": {1: 0}},{} # "Body Mass"
	),
	MobRaces.Ogre: MeshNormData.new(
		["Ogre"], other_races.call(MobRaces.Ogre),
		{"Hair":"empty","Eyelashes":"empty","Beard":"empty","Brows":"empty","Shoes":"empty"},{},
		{"Top":ogre_color_range},{},
		{"Body": {1: 1}},{},#"Body Mass"
		{"mesh_name": ["Accessory","Hair","Brows","Beard"]}
	),
	MobRaces.Statue: MeshNormData.new(
		[], other_races.call(MobRaces.Statue),
		{"Hat":"empty","Accessory": "empty"},{},
		{"EquipmentBulk":statue_color_range,"BodyBulk":statue_color_range},{},
		{"Body": {1: 0}}#"Body Mass"
	),
	MobRaces.Spirit: MeshNormData.new(
		[], other_races.call(MobRaces.Spirit),
		{"Hair":"empty","Eyelashes":"empty","Beard":"empty","Brows":"empty","EquipmentBulk":"empty","Accessory": "empty"},{},
		{
		"Eyes": spirit_eyes_color_range,
		"Top": spirit_skin_color_range
		},{},
		{"Body": {1: 0}},{},#"Body Mass"
		{"mesh_name": ["Accessory","Hair","Beard","Brows"]}
	),
	MobRaces.Skeleton: MeshNormData.new(
		[],other_races.call(MobRaces.Skeleton),
		{"EquipmentBulk":"empty", "BodyBulk":"empty"}
	)
}

# TODO () shape names from mesh / some other place. use shape_id as key instead?
# TODO How to handle body and top separate colors?
var body_mesh_info := {
	"Body": MobMeshInfo.new("", skin_color_ranges, {"Body Shape": [0,1],"Body Mass": [-.5,1],"Body Muscles": [-.5,1]}),
	"Head": MobMeshInfo.new("", null, {
		"Lips Width": [-1,1],"Lips Thickness": [-1,1],"Lip Corner": [-1,1],"Jaw Shape": [-1,1], "Face Length": [-1,1],
		"Eye Lower Lid Height": [-1,1], "Eye Upper Lid Height": [-1,1],"Eye Edge Height": [-1,1]
	}),
	"Eyes": MobMeshInfo.new("", eyes_color_ranges),
	"Eyelashes": MobMeshInfo.new("res://Assets/Mob/face/lashes/"),
	"Hair": MobMeshInfo.new("res://Assets/Mob/hair/", hair_color_ranges),
	"Beard": MobMeshInfo.new("res://Assets/Mob/face/beard/", hair_color_ranges),
	"Brows": MobMeshInfo.new("", hair_color_ranges, {"Brow Thickness": [0,1], "Brow Inner Height": [0,1], "Brow Outer Height": [0,1]})
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
