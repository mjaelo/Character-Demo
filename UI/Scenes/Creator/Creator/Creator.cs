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
	private CreatorCameraManager.CreatorCameraManager _cameraManager = null!;


	public Player Player = null!;
	public MobData MobData  = new();
	private Skeleton3D _skeleton  = null!;
	private TabBuilder _tabBuilder = null!;

	public void Initialize(Player player, Skeleton3D skeleton)
	{
		Player = player;
		_skeleton = skeleton;
		_tabBuilder = new TabBuilder(skeleton, MobData);
		_presetTab = GetNode<PresetTab.PresetTab>("TabContainer/Preset");
		_tabContainer = GetNode<TabContainer>("TabContainer");
		_startButton = GetNode<Button>("Right/Start Game");
		_cameraManager = GetNode<CreatorCameraManager.CreatorCameraManager>("Right/CreatorCameraManager");
		_cameraManager.Initialize(Player);

		_startButton.Pressed += StartGame;
		_presetTab.Initialize(this);

		foreach (var (tabName, pickers) in UiConstants.CreatorMenuData)
			_tabContainer.AddChild(_tabBuilder.GetCreatorTab(pickers, tabName));

		RandomizeCreatorValues();
		MobUtils.TogglePlayerControl(false, player);
		UiUtils.DisableEdit(_startButton, string.IsNullOrEmpty(MobData.MobName));
	}

	private void StartGame()
	{
		GD.Print("starting game with ", MobData.MobName);
		_cameraManager.SetCameraHeightByRace(MobData.Race);
		
		MobUtils.SpawnOpponent(GetParent());
		MobUtils.TogglePlayerControl(true, Player);
		QueueFree();
	}

	public void RandomizeCreatorValues()
	{
		MobData = MobGetter.GetRandomMobData(MobEnums.MobRaces.Human, MobEnums.MobTypes.Civilian);
		MobData.MobName = "";
		MobSetter.SetMobDataToMob(MobData, Player);
		_presetTab.SetMobDataToPresetPickers(MobData);
		SetMobDataToPickers(MobData);
	}

	public void UpdateAllPickers()
	{
		_presetTab.SetMobDataToPresetPickers(MobData);
		SetMobDataToPickers(MobData);
	}

	public void SetMobDataToPickers(MobData mobData)
	{
		foreach (var (meshName, meshInfo) in MobConstants.BodyMeshesInfo)
			SetMeshDataToPickers(MobUtils.GetBodyDataFieldValue(mobData.BodyData, meshInfo.FieldName), meshName);
		foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
			SetMeshDataToPickers(MobUtils.GetEqDataFieldValue(mobData.EquipmentData, meshInfo.FieldName), meshName);
	}

	private void SetMeshDataToPickers(MeshData meshData, string meshName)
	{
		foreach (var (tabName, pickerInfos) in UiConstants.CreatorMenuData)
		{
			var info = pickerInfos.FirstOrDefault(p => p.MeshName == meshName);
			if (info == null) continue;
			if (!string.IsNullOrEmpty(meshData.MeshFile) && info.HasFilePicker)
				FindPickerAndSetValue(meshData.MeshFile, tabName, meshName);
			if (meshData.MeshColors.Count > 0 && info.ColorPickers?.Count > 0)
			{
				// Set each color picker for each material
				for (int i = 0; i < info.ColorPickers.Count && i < meshData.MeshColors.Count; i++)
					if (info.ColorPickers[i])
						FindPickerAndSetValue(meshData.MeshColors[i], tabName, meshName + "Color" + i);
			}
			if (meshData.MeshShapes.Count <= 0 || !info.HasShapePicker) continue;
			var mi = _skeleton.HasNode(meshName) ? _skeleton.GetNode<MeshInstance3D>(meshName) : null;
			if (mi == null) continue;
			var shapeNames = MobUtils.GetShapeNamesFromMesh(mi.Mesh);
			if (shapeNames.Count < meshData.MeshShapes.Count)
			{
				GD.Print("SetMeshDataToPickers ",meshName," wrong shape count. from mesh: ",shapeNames.Count," expected: ",meshData.MeshShapes.Count);
				continue;
			}
			for (int j = 0; j < meshData.MeshShapes.Count; j++)
				FindPickerAndSetValue(meshData.MeshShapes[j], tabName, shapeNames[j]);
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
			case SliderPickerComponent sp:
				var str = value is float f
					? f.ToString(System.Globalization.CultureInfo.InvariantCulture)
					: value.ToString() ?? "";
				sp.SetValue(str);
				break;
			case ColorPickerComponent cp when value is Color c: cp.SetValue(c); break;
			case null: GD.Print("Couldn't find " + pickerName + " in " + tabName); break;
		}
	}
}
