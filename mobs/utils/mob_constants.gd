extends Node


# UTILS FOR CONST
var other_races := func (race_id:int): return MobRaces.keys().filter(func (race): return race != MobRaces.keys()[race_id])

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
const clothes_color_ranges := {"hue": [0.0, .9], "saturation": [0.0, .3], "brightness": [0.2, .6]}
const eyes_color_ranges := {"hue": [0.1, 0.6], "saturation": [0.2, 0.5], "brightness": [0.3, 0.8]}
const skin_color_ranges := {"hue": [0.01, 0.08], "saturation": [0.2, 0.3], "brightness": [0.3, 0.95]}

const variation_chance := 0.1 # chance for non normative gender and body shapes

#const name_list := ["Jeff", "Hanz", "Anabelle", "Eve", "Alex", "Sam", "Think", "Hard", "About", "Your Life Choices"] # TODO () genderize it
const mob_names := {
	Gender.NonBin: ["Alex", "Sam", "Think", "Hard", "About", "Your Life Choices"],
	Gender.Male: ["Jeff", "Hanz", "Louis", "Robert","Clyde","Rupert","Steve"], 
	Gender.Female: ["Anabelle", "Eve", "Penny", "Cleo","Sue"], }

const Statue_Grey := Color(.3, .3, .3, 0)

# for adjusting mob model in a way not covered by body and eq data TODO add shape key override?
const race_action_dict := {
	MobRaces.Human:{},
	MobRaces.Skeleton:{"show_monster_body":true},
	MobRaces.Spirit:{"scale": .75,"eye_whites":Color(100, 100, 100, 1.0)},
	MobRaces.Ogre:{"scale": 1.5,"eye_whites":Color.ORANGE},
	MobRaces.Demon:{"eye_whites":Color.BLACK},
	MobRaces.Statue:{},
}

# VAR CONST

# TODO () tags full-hide, no-hide.
# TODO () use it for validation. use 
var known_tags := ["masculine","feminine", MobTypes.keys(), MobRaces.keys(), "full-hat"] 

var gender_norms := {
	Gender.Male: MeshNormData.new(
		[],["feminine"],
		{},{},
		{},{},
		{"Body":{0: 0, 8: -1},"Brows":{0: 1}},#"Body Shape","Lips Width" "Brow Thickness"
		{"shape":{"Body": [0]}}  #"enforce": ["Body Shape"]
	),
	Gender.NonBin: MeshNormData.new(),
	Gender.Female: MeshNormData.new(
		[],["masculine"],
		{"Beard":"empty"},{"Hair":"empty"},
		{},{},
		{"Body":{0: .5, 8: 1},"Brows":{0: 0}},#"Body Shape","Lips Width", "Brow Thickness"
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
		[], other_races.call(MobRaces.Human), # enforce
		{"Accesory": "empty"},{},
		{},{},
		{"Body": {1: 0}},{}, # "Body Mass"
		{"mesh_name": ["Accesory"]}
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
		{"Body": {1: 1}}#"Body Mass"
	),
	MobRaces.Statue: MeshNormData.new(
		[], other_races.call(MobRaces.Statue),
		{"Hat":"empty","Accesory": "empty"},{},
		{"EquipmentBulk":Statue_Grey,"BodyBulk":Statue_Grey},
		{"Body": {1: 0}}#"Body Mass"
	),
	MobRaces.Spirit: MeshNormData.new(
		[], other_races.call(MobRaces.Spirit),
		{"Hair":"empty","Eyelashes":"empty","Beard":"empty","Brows":"empty","EquipmentBulk":"empty","Accesory": "empty"},{},
		{
			"Eyes": Color(10, 10, 10, 1.0),
			"Body": [
				range(10).map(func (n): return n/10.0),
				[5], [5],
				[1.0]]#(randf()*11, randf()*11, randf()*11, 1.0),
		},
		{"Body": {1: 0}},#"Body Mass"
		{"mesh_name": ["Accesory","Hair","Beard","Brows"]}
	),
	MobRaces.Skeleton: MeshNormData.new(
		[],other_races.call(MobRaces.Skeleton),
		{"EquipmentBulk":"empty", "BodyBulk":"empty"}
	)
}

# TODO () shape names from mesh / some other place. use shape_id as key instead
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
		"Accesory": {
			"mesh_folder": "res://assets/mob/accessories/",
		},
}
