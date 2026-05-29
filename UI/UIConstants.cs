using System.Collections.Generic;
using CharacterDemo.General.Services;
using CharacterDemo.UI.InfoFiles;
using Godot;

namespace CharacterDemo.UI;

public static class UiConstants
{
	// strings
	public const string OverrideWarning = "Overriding preset with the same name";
	public const string NewPresetName = "empty"; // not visible name of an default empty preset (randomized MD)

	// styling
	public const float PickerPadding = 10.0f;

	// assets
	public const string WarningIconPath = "res://Assets/UI/UiIcons/Warning.png";
	public const string PresetFile = "preset.json";
	public const string PresetPath = "res://UI/Scenes/Creator/";
	private const string CreatorMenuDataPath = "res://Assets/UI/InfoFiles/CreatorMenuData.json";
	private const string SliderPickerPath = "res://UI/Scenes/Utility/SliderPicker/SliderPickerComponent.tscn";
	private const string ColorPickerPath = "res://UI/Scenes/Utility/ColorPicker/ColorPickerComponent.tscn";

	public static PackedScene SliderPickerScene => ResourceLoader.Load<PackedScene>(SliderPickerPath);
	public static PackedScene ColorPickerScene => ResourceLoader.Load<PackedScene>(ColorPickerPath);

	public static readonly IReadOnlyDictionary<string, MeshPickerInfo[]> CreatorMenuData =
		FileService.LoadJson<Dictionary<string, MeshPickerInfo[]>>(CreatorMenuDataPath) ??
		new Dictionary<string, MeshPickerInfo[]>();
}
