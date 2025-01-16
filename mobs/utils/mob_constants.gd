extends Node

enum MobTypes {Civilian, Guard, Noble, Merchant, Farmer}
enum MobRaces {Human,Skeleton,Ogre,Spirit,Demon,Statue}
enum Gender {Male,NonBin,Female}

# TODO () tags full-hide, no-hide.
const known_tags := ["masculine","feminine","Guard","Noble","Merchant","Farmer","full-hat"] # TODO () use it for validation
const hand_names := ["Right Hand","Left Hand"]
const non_empty_names := ["Top","Bottom","Shoes","Eyelashes"]
const hair_linked_names := ["Brows","Beard"]
const half_empty_names := ["Hat", "Beard"]
const gendered_mesh_names := ["Beard","Eyelashes"]
const hip_movers := ["Body Shape", "Body Mass"]

const hair_color_ranges := {"hue": [0,.2], "saturation": [.1,.4], "brightness": [0,.7]} 
const clothes_color_ranges := {"hue": [0.0, .9], "saturation": [0.0, .3], "brightness": [0.2, .6]}
const eyes_color_ranges := {"hue": [0.1, 0.6], "saturation": [0.2, 0.5], "brightness": [0.3, 0.8]}
const skin_color_ranges := {"hue": [0.01, 0.08], "saturation": [0.2, 0.3], "brightness": [0.3, 0.95]}

const variation_chance := 0.1 # chance for non normative gender and body shapes
