using System.Linq;
using CharacterDemo.Mob;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.Scenes.Player;
using CharacterDemo.Mob.Services.MobGeneration;
using CharacterDemo.UI.Services;
using Godot;
using ColorPickerComponent = CharacterDemo.UI.Scenes.Utility.ColorPicker.ColorPickerComponent;
using SliderPickerComponent = CharacterDemo.UI.Scenes.Utility.SliderPicker.SliderPickerComponent;

namespace CharacterDemo.UI.Scenes.Creator;

public partial class Creator : Control
{
	private TabContainer _tabContainer = null!;
	private PresetTab.PresetTab _presetTab = null!;
	private Button _startButton = null!;

	public Player Player { get; private set; } = null!;
	public Skeleton3D Skeleton { get; private set; } = null!;
	public MobData MobData { get; set; } = new();
	public TabBuilder TabBuilder { get; private set; } = null!;

	public void Initialize(Player player, Skeleton3D skeleton)
	{
		Player = player;
		Skeleton = skeleton;
		TabBuilder = new TabBuilder(skeleton, MobData);
		_presetTab = GetNode<PresetTab.PresetTab>("TabContainer/Preset");
		_tabContainer = GetNode<TabContainer>("TabContainer");
		_startButton = GetNode<Button>("CreatorCameraManager/Start Game");
		_presetTab.Initialize(this);

		foreach (var (tabName, pickers) in UiConstants.CreatorMenuData)
			_tabContainer.AddChild(TabBuilder.CreateTab(pickers, tabName));

		RandomizeCreatorValues();
		MobUtils.TogglePlayerControl(false, player);
		UiUtils.DisableEdit(_startButton, string.IsNullOrEmpty(MobData.MobName));
	}

	public void StartGame()
	{
		GD.Print("starting game with ", MobData.MobName);
		MobUtils.SpawnOpponent(GetParent());
		MobUtils.TogglePlayerControl(true, Player);
		QueueFree();
	}

	public void RandomizeCreatorValues()
	{
		MobData = MobGetter.GetRandomMobData(Skeleton, MobEnums.MobRaces.Human, MobEnums.MobTypes.Civilian);
		MobData.MobName = "";
		TabBuilder.MobData = MobData;
		MobSetter.SetMobDataToMob(MobData, Player);
		_presetTab.SetMobDataToPresetPickers(MobData);
		SetMobDataToPickers(MobData);
	}

	public void UpdateAllPickers()
	{
		TabBuilder.MobData = MobData;
		_presetTab.SetMobDataToPresetPickers(MobData);
		SetMobDataToPickers(MobData);
	}

	public void SetMobDataToPickers(MobData mobData)
	{
		foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
			SetMeshDataToPickers(MobGetter.GetBodyMeshData(mobData.BodyData, meshInfo.FieldName), meshName);
		foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
			SetMeshDataToPickers(MobGetter.GetEqMeshData(mobData.EquipmentData, meshInfo.FieldName), meshName);
	}

	private void SetMeshDataToPickers(MeshData meshData, string meshName)
	{
		foreach (var (tabName, pickerInfos) in UiConstants.CreatorMenuData)
		{
			var info = pickerInfos.FirstOrDefault(p => p.MeshName == meshName);
			if (info == null) continue;
			if (!string.IsNullOrEmpty(meshData.MeshFile) && info.HasFilePicker)
				FindPickerAndSetValue(meshData.MeshFile, tabName, meshName);
			if (meshData.MeshColor != new Color() && info.HasColorPicker)
				FindPickerAndSetValue(meshData.MeshColor, tabName, meshName + "Color");
			if (meshData.MeshShape.Count <= 0 || !info.HasShapePicker) continue;
			var mi = Skeleton.HasNode(meshName) ? Skeleton.GetNode<MeshInstance3D>(meshName) : null;
			if (mi == null) continue;
			var shapeNames = MobUtils.GetShapeNamesFromMesh(mi.Mesh);
			for (int j = 0; j < meshData.MeshShape.Count; j++)
				FindPickerAndSetValue(meshData.MeshShape[j], tabName, shapeNames[j]);
		}
	}

	private void FindPickerAndSetValue(object value, string tabName, string pickerName)
	{
		var tab = _tabContainer.FindChild(tabName, true, false);
		if (tab == null)
		{
			GD.Print("couldn't find tab ", tabName);
			return;
		}

		tab = tab.GetChild(0).GetChild(0);
		var picker = tab.FindChild(pickerName, true, false);
		switch (picker)
		{
			case SliderPickerComponent sp: sp.SetValue(value.ToString() ?? ""); break;
			case ColorPickerComponent cp when value is Color c: cp.SetValue(c); break;
			case null: GD.Print("Couldn't find " + pickerName + " in " + tabName); break;
		}
	}
}
