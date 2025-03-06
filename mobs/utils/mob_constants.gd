extends Node


# UTILS FOR CONST
var other_races := func (race_id:int)->Array: return MobRaces.keys().filter(func (race): return race != MobRaces.keys()[race_id])
var race_cam_height := func (race_id:int)->float: return race_cam_heights.default if !race_cam_heights.has(race_id) else race_cam_heights[race_id]
var get_random_gender := func ()->int: return [Gender.Male,Gender.Female].pick_random() if randf()> variation_chance else Gender.NonBin

# ENMUS
enum MobTypes {Civilian, Guard, Noble, Merchant, Farmer}
enum MobRaces {Human,Skeleton,Ogre,Spirit,Demon,Statue}
enum Gender {Male,NonBin,Female}

# CONST
const hand_names := ["Right Hand","Left Hand"]
const weapon_names := ["Sword","Shield"]
const non_empty_names := ["Top","Bottom","Shoes","Eyelashes"]
const hair_linked_names := ["Brows","Beard"]
const half_empty_names := ["Hat", "Beard"]
const gendered_mesh_names := ["Beard","Eyelashes"]
const hip_movers := ["Body Shape", "Body Mass"]
const shape_control_meshes := ["Body","Brows"] # meshes with shape keys

const hair_color_ranges := {"hue": [0,.2], "saturation": [.1,.4], "brightness": [0,.7]} 
const clothes_color_ranges := {"hue": [0.0, .27], "saturation": [0.0, .3], "brightness": [0.2, .6]}
const eyes_color_ranges := {"hue": [0.1, 0.6], "saturation": [0.2, 0.5], "brightness": [0.3, 0.8]}
const skin_color_ranges := {"hue": [0.01, 0.08], "saturation": [0.2, 0.3], "brightness": [0.3, 0.95]}

const variation_chance := 0.1 # chance for non normative gender and body shapes

const mob_names := {
	Gender.NonBin: ["Alex", "Sam", "Think", "Hard", "About", "Your Life Choices"],
	Gender.Male: ["Jeff", "Hanz", "Louis", "Robert","Clyde","Rupert","Steve"], 
	Gender.Female: ["Anabelle", "Eve", "Penny", "Cleo","Sue"], }

const Statue_Grey := Color(.3, .3, .3, 0)

# for adjusting mob model in a way not covered by body and eq data TODO add shape key override?
const race_action_dict := {
	MobRaces.Human:{},
	MobRaces.Skeleton:{"show_monster_body":true},
	MobRaces.Spirit:{"scale": .75,"eye_whites":Color(100, 100, 100, 1.0),"eye_pupil":Color(100, 100, 100, 1.0)},
	MobRaces.Ogre:{"scale": 1.5,"eye_whites":Color.ORANGE},
	MobRaces.Demon:{"eye_whites":Color.BLACK},
	MobRaces.Statue:{},
}

const race_cam_heights :={
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
		{"Body":{0: .5, 8: 1},"Brows":{0: 0}},{},#"Body Shape","Lips Width", "Brow Thickness"
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
		{"Accessory": "empty"},{},
		{},{},
		{"Body": {1: 0}},{}, # "Body Mass"
		{"mesh_name": ["Accessory"],"tags":other_races.call(MobRaces.Human)}
	),
	MobRaces.Demon: MeshNormData.new(
		["Demon"], other_races.call(MobRaces.Demon),
		{},{},
		{
			"Body": Color.DARK_RED,
			"EquipmentBulk":Color.BLACK,
		},{},
		{"Body": {1: 0}},{} # "Body Mass"
	),
	MobRaces.Ogre: MeshNormData.new(
		["Ogre"], other_races.call(MobRaces.Ogre),
		{"Hair":"empty","Eyelashes":"empty","Beard":"empty","Brows":"empty","Shoes":"empty"},{},
		{"Body":Color.DARK_OLIVE_GREEN},{},
		{"Body": {1: 1}},{},#"Body Mass"
		{"mesh_name": ["Accessory","Hair","Brows","Beard"]}
	),
	MobRaces.Statue: MeshNormData.new(
		[], other_races.call(MobRaces.Statue),
		{"Hat":"empty","Accessory": "empty"},{},
		{"EquipmentBulk":Statue_Grey,"BodyBulk":Statue_Grey},{},
		{"Body": {1: 0}}#"Body Mass"
	),
	MobRaces.Spirit: MeshNormData.new(
		[], other_races.call(MobRaces.Spirit),
		{"Hair":"empty","Eyelashes":"empty","Beard":"empty","Brows":"empty","EquipmentBulk":"empty","Accessory": "empty"},{},
		{
			"Eyes": Color(10, 10, 10, 1.0),
			"Body": [
				range(10).map(func (n): return n/10.0),
				[2], [2],
				[1.0]]#(randf()*11, randf()*11, randf()*11, 1.0),
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
var body_mesh_info := {
	"Body": {
		"color_range": skin_color_ranges,
		"shape_limits":{
			"Body Shape": [0,1],"Body Mass": [-.5,1],"Body Muscles": [-.5,1],
			"Lips Width": [-1,1],"Jaw Shape": [-1,1], "Face Length": [-.5,.5],
			"Eye Lower Lid": [-1,1], "Eye Upper Lid": [-1,1],"Eye Edge": [-1,1]
		}
	},
	"Eyes": {
		"color_range": eyes_color_ranges
	},
	"Eyelashes": {
		"mesh_folder": "res://assets/mob/face/lashes/",
	},
	"Hair": {
		"mesh_folder": "res://assets/mob/hair/",
		"color_range": hair_color_ranges
	},
	"Beard": {
		"mesh_folder": "res://assets/mob/face/beard/",
		"color_range": hair_color_ranges,
	},
	"Brows": {
		"color_range": hair_color_ranges,
	},
}

var eq_mesh_info := {
		"Top": {
			"mesh_folder": "res://assets/mob/top/",
			"color_range": clothes_color_ranges
		},
		"Bottom": {
			"mesh_folder": "res://assets/mob/bottom/",
			"color_range": clothes_color_ranges
		},
		"Shoes": {
			"mesh_folder": "res://assets/mob/shoes/",
			"color_range": clothes_color_ranges
		},
		"Hat": {
			"mesh_folder": "res://assets/mob/hat/",
			"color_range": clothes_color_ranges
		},
		"Right Hand": {
			"mesh_folder": "res://assets/mob/r_hand/",
		},
		"Left Hand": {
			"mesh_folder": "res://assets/mob/l_hand/",
		},
		"Accessory": {
			"mesh_folder": "res://assets/mob/accessories/",
		},
}
