using System.Collections.Generic;
using CharacterDemo.General;
using CharacterDemo.General.Services;
using CharacterDemo.Mob;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.InfoFiles;
using CharacterDemo.Mob.Services.MobGeneration;
using CharacterDemo.UI.Scenes.Utility.SliderPicker;
using Godot;

namespace CharacterDemo.UI.Scenes.Creator.PresetTab;

public partial class PresetTab : TabBar
{
	private Creator _parent = null!;
	private Button _startButton = null!, _saveButton = null!, _deleteButton = null!;
	private SliderPickerComponent _presetPicker = null!, _typePicker = null!, _racePicker = null!;
	private HSlider _genderPicker = null!;
	private LineEdit _namePicker = null!;
	private CreatorCameraManager.CreatorCameraManager _cameraManager = null!;
	private readonly Dictionary<string, MobData> _presets = 
		FileService.LoadJson<Dictionary<string, MobData>>(UiConstants.PresetPath + UiConstants.PresetFile) ?? new();

	public void Initialize(Creator parent)
	{
		_parent = parent;
		_startButton = GetNode<Button>("../../Right/Start Game");
		_saveButton = GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Save Preset");
		_deleteButton = GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Delete Preset");
		_presetPicker = GetNode<SliderPickerComponent>("ScrollContainer/VBoxContainer/Preset");
		_typePicker = GetNode<SliderPickerComponent>("ScrollContainer/VBoxContainer/MobType");
		_racePicker = GetNode<SliderPickerComponent>("ScrollContainer/VBoxContainer/Race");
		_genderPicker = GetNode<HSlider>("ScrollContainer/VBoxContainer/GenderContainer/EditGender");
		_namePicker = GetNode<LineEdit>("ScrollContainer/VBoxContainer/NamePicker");
		_cameraManager = GetNode<CreatorCameraManager.CreatorCameraManager>("../../Right/CreatorCameraManager");
		
		GetNode<TextureButton>("ScrollContainer/VBoxContainer/CharacterName/RandomName").Pressed += OnRandomNamePressed;
		GetNode<Button>("ScrollContainer/VBoxContainer/HBoxContainer/RandomBody").Pressed += OnRandomBodyPressed;
		GetNode<Button>("ScrollContainer/VBoxContainer/HBoxContainer/RandomClothes").Pressed += OnRandomClothesPressed;
		
		_presetPicker.Init([.. _presets.Keys], "Preset");
		_presetPicker.VariableChanged += v => OnPresetChanged((string)v);
		_typePicker.Init(System.Enum.GetNames<MobEnums.MobTypes>(), "Mob Type");
		_typePicker.VariableChanged += v => OnTypeChanged((string)v);
		_racePicker.Init(System.Enum.GetNames<MobEnums.MobRaces>(), "Race");
		_racePicker.VariableChanged += v => OnRaceChanged((string)v);
		_genderPicker.ValueChanged += v => OnGenderChanged((int)v);
		_namePicker.TextChanged += OnMobNameChanged;
		
		UiUtils.DisableEdit(GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Save Preset"), string.IsNullOrEmpty(parent.MobData.MobName));
		UiUtils.DisableEdit(GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Delete Preset"), true);
	}

	public void SetMobDataToPresetPickers(MobData mobData)
	{
		_namePicker.Text = mobData.MobName;
		_typePicker.Picker!.Value = (int)mobData.Type;
		_racePicker.Picker!.Value = (int)mobData.Race;
		_genderPicker.Value = (int)mobData.Gender;
	}

	private void OnPresetChanged(string mobName)
	{
		bool isNew = mobName == UiConstants.DefaultPresetName;
		UiUtils.DisableEdit(_deleteButton, isNew);
		if (!isNew && _presets.TryGetValue(mobName, out var md))
		{
			_parent.MobData = md;
			MobSetter.SetMobDataToMob(md, _parent.Player);
			_parent.UpdateAllPickers();
		}
		else _parent.RandomizeCreatorValues();
	}

	private void OnGenderChanged(int gender)
	{
		if ((int)_parent.MobData.Gender == gender) return;
		_parent.MobData.Gender = (MobEnums.Gender)gender;
		if (gender != (int)MobEnums.Gender.NonBin)
		{
			var norms = new List<NormInfo>(MobConstants.GenderNorms[(MobEnums.Gender)gender]);
			_parent.MobData.BodyData = MobAdjuster.AdjustBodyData(norms, _parent.MobData.BodyData);
			_parent.MobData.EquipmentData = MobAdjuster.AdjustEquipmentData(norms, _parent.MobData.EquipmentData);
		}
		MobSetter.SetMobDataToMob(_parent.MobData, _parent.Player);
		_parent.UpdateAllPickers();
	}

	private void OnMobNameChanged(string newText)
	{
		if (_parent.MobData.MobName == newText) return;
		_parent.MobData.MobName = newText;
		UiUtils.DisableEdit(_startButton, string.IsNullOrEmpty(newText));
		UiUtils.DisableEdit(_saveButton, string.IsNullOrEmpty(newText));
		if (_presets.ContainsKey(newText)) UiUtils.ButtonShowWarning(_saveButton, UiConstants.OverrideWarning);
		else UiUtils.ButtonHideWarning(_saveButton);
	}

	private void OnRaceChanged(string raceV)
	{
		var race = System.Enum.Parse<MobEnums.MobRaces>(raceV);
		_cameraManager.SetCameraHeightByRace(race);
		if (_parent.MobData.Race == race) return;
		_parent.MobData.Race = race;
		var norms = new List<NormInfo>(MobConstants.RaceNorms[race]);
		_parent.MobData.BodyData = MobAdjuster.AdjustBodyData(norms, _parent.MobData.BodyData);
		_parent.MobData.EquipmentData = MobAdjuster.AdjustEquipmentData(norms, _parent.MobData.EquipmentData);
		MobSetter.SetMobDataToMob(_parent.MobData, _parent.Player);
		_parent.SetMobDataToPickers(_parent.MobData);
	}

	private void OnTypeChanged(string typeV)
	{
		var type = System.Enum.Parse<MobEnums.MobTypes>(typeV);
		if (_parent.MobData.Type == type) return;
		_parent.MobData.Type = type;
		OnRandomClothesPressed();
	}

	private void OnRandomNamePressed()
	{
		var possibleNames = MobConstants.MobNames[_parent.MobData.Gender];
		var newName = GeneralUtils.PickRandom(possibleNames);
		_namePicker.Text = newName;
		OnMobNameChanged(newName);
	}

	private void OnRandomBodyPressed()
	{
		var norms = MobGetter.GetRtgNorms(_parent.MobData.Race, _parent.MobData.Type, _parent.MobData.Gender);
		_parent.MobData.BodyData = MobGetter.GetRandomBodyData(norms);
		MobSetter.SetBodyData(_parent.MobData.BodyData, _parent.Player);
		_parent.SetMobDataToPickers(_parent.MobData);
	}

	private void OnRandomClothesPressed()
	{
		var norms = MobGetter.GetRtgNorms(_parent.MobData.Race, _parent.MobData.Type, _parent.MobData.Gender);
		_parent.MobData.EquipmentData = MobGetter.GetRandomEquipmentData(norms);
		MobSetter.SetEquipmentData(_parent.MobData.EquipmentData, _parent.Player);
		_parent.SetMobDataToPickers(_parent.MobData);
	}

}
