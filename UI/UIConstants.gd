extends Node
## UiConstants — globally available UI constants.

# Creator
const OVERRIDE_WARNING := "Overriding preset with the same name"
const DEFAULT_PRESET_NAME := "New Character"

# Camera
const CREATOR_CAMERA_SENSITIVITY := 2
const GAME_CAMERA_SENSITIVITY := 5
const CAMERA_MAX_HEIGHT := 10.0
const CREATOR_CAMERA_ZOOM_OFFSET := 2.0

# Picker padding
const PICKER_PADDING := 10.0

# Paths
const WARNING_ICON_PATH := "res://Assets/UI/Warning.png"
var SLIDER_PICKER_SCENE: PackedScene = load("res://UI/Scenes/Utility/SliderPicker/SliderPickerComponent.tscn")
var COLOR_PICKER_SCENE: PackedScene = load("res://UI/Scenes/Utility/ColorPicker/ColorPickerComponent.tscn")

# tab name > mesh name > pickers for mesh, color, shape
var menu_data := {
	"Body":[ 
		MeshPickerInfo.new("Body",false,true,true)
	],
	"Face": [
		MeshPickerInfo.new("Eyes",false,true),
		MeshPickerInfo.new("Eyelashes",true,false),
		MeshPickerInfo.new("Head",false,false,true),
		MeshPickerInfo.new("Accessory",true,false,false)
	],
	"Hair": [
		MeshPickerInfo.new("Hair",true,true),
		MeshPickerInfo.new("Brows",false,true,true),
		MeshPickerInfo.new("Beard",true,true)
	],
	"Clothes": [
		MeshPickerInfo.new("Top",true,true),
		MeshPickerInfo.new("Bottom",true,true),
		MeshPickerInfo.new("Shoes",true,true),
		MeshPickerInfo.new("Hat",true,true),
		MeshPickerInfo.new("Right Hand",true,false),
		MeshPickerInfo.new("Left Hand",true,false)
	],
}
