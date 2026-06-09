using System;
using System.Collections.Generic;
using CharacterDemo.General;
using CharacterDemo.General.Services;
using CharacterDemo.Mob;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.InfoFiles;
using CharacterDemo.Mob.Services.MobGeneration;
using CharacterDemo.UI.Scenes.Utility.SliderPicker;
using Godot;

namespace CharacterDemo.UI.Scenes.Creator;

public partial class PresetTab : TabBar
{
	private Creator _parent = null!;
	private Button _startButton = null!, _savePresetButton = null!, _deletePresetButton = null!;
	private SliderPickerComponent _presetPicker = null!, _typePicker = null!, _racePicker = null!;
	private HSlider _genderPicker = null!;
	private LineEdit _namePicker = null!;
	private CreatorCameraManager.CreatorCameraManager _cameraManager = null!;
	private readonly IDictionary<string, MobData> _presets =
		FileService.LoadJson<IDictionary<string, MobData>>(UiConstants.PresetPath + UiConstants.PresetFile)
		?? new Dictionary<string, MobData>();

	public void Initialize(Creator parent)
	{
		_parent = parent;
		_startButton = GetNode<Button>("../../Right/Start Game");
		_savePresetButton = GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Save Preset");
		_deletePresetButton = GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Delete Preset");
		_presetPicker = GetNode<SliderPickerComponent>("ScrollContainer/VBoxContainer/Preset");
		_typePicker = GetNode<SliderPickerComponent>("ScrollContainer/VBoxContainer/MobType");
		_racePicker = GetNode<SliderPickerComponent>("ScrollContainer/VBoxContainer/Race");
		_genderPicker = GetNode<HSlider>("ScrollContainer/VBoxContainer/GenderContainer/EditGender");
		_namePicker = GetNode<LineEdit>("ScrollContainer/VBoxContainer/NamePicker");
		_cameraManager = GetNode<CreatorCameraManager.CreatorCameraManager>("../../Right/CreatorCameraManager");
		
		GetNode<TextureButton>("ScrollContainer/VBoxContainer/CharacterName/RandomName").Pressed += OnRandomNamePressed;
		GetNode<Button>("ScrollContainer/VBoxContainer/HBoxContainer/RandomBody").Pressed += OnRandomBodyPressed;
		GetNode<Button>("ScrollContainer/VBoxContainer/HBoxContainer/RandomClothes").Pressed += OnRandomClothesPressed;
		
		_presetPicker.Init((List<string>)[UiConstants.NewPresetName, .. _presets.Keys], "Preset");
		_presetPicker.VariableChanged += v => OnPresetChanged((string)v);
		_typePicker.Init(Enum.GetNames<MobEnums.MobTypes>(), "Mob Type");
		_typePicker.VariableChanged += v => OnTypeChanged((string)v);
		_racePicker.Init(Enum.GetNames<MobEnums.MobRaces>(), "Race");
		_racePicker.VariableChanged += v => OnRaceChanged((string)v);
		_genderPicker.ValueChanged += v => OnGenderChanged((int)v);
		_namePicker.TextChanged += OnMobNameChanged;
		_savePresetButton.Pressed += OnSavePresetPressed;
		_deletePresetButton.Pressed += OnDeletePresetPressed;
		
		UiUtils.DisableEdit(GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Save Preset"), string.IsNullOrEmpty(parent.MobData.MobName));
		UiUtils.DisableEdit(GetNode<Button>("ScrollContainer/VBoxContainer/Preset Handler/Delete Preset"), true);
	}

	public void SetMobDataToPresetPickers(MobData mobData)
	{
		_namePicker.Text = mobData.MobName;
		_typePicker.SetValue(mobData.Type.ToString());
		_racePicker.SetValue(mobData.Race.ToString());
		_genderPicker.Value = (int)mobData.Gender;
	}

	private void OnPresetChanged(string mobName)
	{
		_parent.UpdatePrevMobData();
		bool isNew = mobName == UiConstants.NewPresetName;
		GD.Print("disabling edit = ",isNew);
		UiUtils.DisableEdit(_deletePresetButton, isNew);
		UiUtils.DisableEdit(_savePresetButton, isNew);
		if (!isNew && _presets.TryGetValue(mobName, out var md))
		{
			UiUtils.ButtonShowWarning(_savePresetButton, UiConstants.OverrideWarning);
			var newMobData = md.Duplicate();
			_parent.MobData = newMobData;
			MobSetter.SetMobDataToMob(newMobData, _parent.Player);
			_parent.UpdateAllPickers();
			return;
		}

		GD.Print(mobName+" not found in presets");
		_parent.RandomizeCreatorValues();

	}

	private void OnGenderChanged(int gender)
	{
		if ((int)_parent.MobData.Gender == gender) return;
		_parent.UpdatePrevMobData();
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
		UiUtils.DisableEdit(_savePresetButton, string.IsNullOrEmpty(newText));
		if (_presets.ContainsKey(newText)) UiUtils.ButtonShowWarning(_savePresetButton, UiConstants.OverrideWarning);
		else UiUtils.ButtonHideWarning(_savePresetButton);
	}

	private void OnSavePresetPressed()
	{
		var newData = _parent.MobData.Duplicate();
		_presets[newData.MobName] = newData;
		_presetPicker.UpdateValues([UiConstants.NewPresetName, .. _presets.Keys]);
		UiUtils.DisableEdit(_deletePresetButton, false);
		UiUtils.ButtonShowWarning(_savePresetButton, UiConstants.OverrideWarning);
		FileService.SaveJson(_presets, UiConstants.PresetPath + UiConstants.PresetFile);
		_presetPicker.SetValue(newData.MobName);
	}
	
	private void OnDeletePresetPressed()
	{
		var currentName = _parent.MobData.MobName;
		_presets.Remove(currentName);
		_presetPicker.UpdateValues([UiConstants.NewPresetName, .. _presets.Keys]);
		_presetPicker.SetValue(UiConstants.NewPresetName);
		UiUtils.DisableEdit(_deletePresetButton, true);
		FileService.SaveJson(_presets, UiConstants.PresetPath + UiConstants.PresetFile);
		_parent.RandomizeCreatorValues();
	}

	private void OnRaceChanged(string raceV)
	{
		var race = Enum.Parse<MobEnums.MobRaces>(raceV);
		_cameraManager.SetCameraHeightByRace(race);
		if (_parent.MobData.Race == race) return;
		_parent.UpdatePrevMobData();
		_parent.MobData.Race = race;
		var norms = new List<NormInfo>(MobConstants.RaceNorms[race]);
		_parent.MobData.BodyData = MobAdjuster.AdjustBodyData(norms, _parent.MobData.BodyData);
		_parent.MobData.EquipmentData = MobAdjuster.AdjustEquipmentData(norms, _parent.MobData.EquipmentData);
		MobSetter.SetMobDataToMob(_parent.MobData, _parent.Player);
		_parent.SetMobDataToPickers(_parent.MobData);
	}

	private void OnTypeChanged(string typeV)
	{
		var type = Enum.Parse<MobEnums.MobTypes>(typeV);
		if (_parent.MobData.Type == type) return;
		_parent.UpdatePrevMobData();
		_parent.MobData.Type = type;
		OnRandomClothesPressed();
	}

	private void OnRandomNamePressed()
	{
		_parent.UpdatePrevMobData();
		var possibleNames = MobConstants.MobNames[_parent.MobData.Gender];
		var newName = GeneralUtils.PickRandom(possibleNames);
		_namePicker.Text = newName;
		OnMobNameChanged(newName);
	}

	private void OnRandomBodyPressed()
	{
		_parent.UpdatePrevMobData();
		var norms = MobGetter.GetRtgNorms(_parent.MobData.Race, _parent.MobData.Type, _parent.MobData.Gender);
		_parent.MobData.BodyData = MobGetter.GetRandomBodyData(norms);
		MobSetter.SetBodyData(_parent.MobData.BodyData, _parent.Player);
		_parent.SetMobDataToPickers(_parent.MobData);
	}

	private void OnRandomClothesPressed()
	{
		_parent.UpdatePrevMobData();
		var norms = MobGetter.GetRtgNorms(_parent.MobData.Race, _parent.MobData.Type, _parent.MobData.Gender);
		Color? skinColor = _parent.MobData.BodyData.HeadMesh.MeshColors.Count > 0 ? _parent.MobData.BodyData.HeadMesh.MeshColors[0] : null;
		_parent.MobData.EquipmentData = MobGetter.GetRandomEquipmentData(norms, null,skinColor);
		MobSetter.SetEquipmentData(_parent.MobData.EquipmentData, _parent.Player);
		_parent.SetMobDataToPickers(_parent.MobData);
	}
	
}
