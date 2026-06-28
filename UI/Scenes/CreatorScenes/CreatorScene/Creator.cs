using System.Globalization;
using System.Linq;
using CharacterDemo.Mobs;
using CharacterDemo.Mobs.DataFiles;
using CharacterDemo.Mobs.Scenes.PlayerScene;
using CharacterDemo.Mobs.Services.MobGeneration;
using CharacterDemo.UI.Scenes.CreatorScenes.CreatorCameraManagerScene;
using CharacterDemo.UI.Scenes.CreatorScenes.PresetTabScene;
using Godot;
using ColorPickerComponent = CharacterDemo.UI.Scenes.UtilityScenes.ColorPickerScene.ColorPickerComponent;
using SliderPickerComponent = CharacterDemo.UI.Scenes.UtilityScenes.SliderPickerScene.SliderPickerComponent;

namespace CharacterDemo.UI.Scenes.CreatorScenes.CreatorScene;

public partial class Creator : Control
{
	private TabContainer _tabContainer = null!;
	private PresetTab _presetTab = null!;
	private Button _startButton = null!;
	private TextureButton _undoButton = null!;
	private CreatorCameraManager _cameraManager = null!;
	
	public Player Player = null!;
	private MobData? _prevData;
	public MobData MobData  = new();
	private Skeleton3D _skeleton  = null!;
	private TabBuilder _tabBuilder = null!;

	public void Initialize(Player player, Skeleton3D skeleton)
	{
		Player = player;
		_skeleton = skeleton;
		_tabBuilder = new TabBuilder(skeleton, this);
		_presetTab = GetNode<PresetTab>("TabContainer/Preset");
		_tabContainer = GetNode<TabContainer>("TabContainer");
		_startButton = GetNode<Button>("Right/Start Game");
		_undoButton = GetNode<TextureButton>("UndoButton");
		_cameraManager = GetNode<CreatorCameraManager>("Right/CreatorCameraManager");
		_cameraManager.Initialize(Player);

		_startButton.Pressed += StartGame;
		_undoButton.Pressed += UndoChange;
		_presetTab.Initialize(this);

		foreach (var (tabName, pickers) in UiConstants.CreatorMenuData)
			_tabContainer.AddChild(_tabBuilder.GetCreatorTab(pickers, tabName));

		RandomizeCreatorValues();
		MobUtils.TogglePlayerControl(false, player);
		UiUtils.DisableEdit(_startButton, string.IsNullOrEmpty(MobData.MobName));
		UiUtils.DisableEdit(_undoButton, true);
	}

	private void UndoChange()
	{
		if (_prevData == null) return;
		MobData = _prevData.Duplicate();
		MobDataSetter.SetMobDataToMob(MobData, Player);
		UpdateAllPickers();
		_presetTab.SetMobDataToPresetPickers(MobData);
		UiUtils.DisableEdit(_undoButton, true);
	}

	public void UpdatePrevMobData()
	{
		_prevData = MobData.Duplicate();
		UiUtils.DisableEdit(_undoButton, false);
	}

	private void StartGame()
	{
		GD.Print("starting game with ", MobData.MobName);
		_cameraManager.SetCameraHeightByRace(MobData.Race);
		
		MobUtils.SpawnOpponent(GetParent());
		MobUtils.TogglePlayerControl(true, Player);
		
		GetNode<StatsScene.Stats>("../AnimStats").Visible = true;
		
		QueueFree();
	}

	public void RandomizeCreatorValues()
	{
		MobData = MobDataGetter.GetRandomMobData(MobEnums.MobRaces.Human, MobEnums.MobTypes.Civilian);
		MobData.MobName = "";
		MobDataSetter.SetMobDataToMob(MobData, Player);
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
			SetMeshDataToPickers(MobDataGetter.GetBodyDataFieldValue(mobData.BodyData, meshInfo.FieldName), meshName);
		foreach (var (meshName, meshInfo) in MobConstants.EqMeshesInfo)
			SetMeshDataToPickers(MobDataGetter.GetEqDataFieldValue(mobData.EquipmentData, meshInfo.FieldName), meshName);
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
			var shapeNames = MobGetter.GetShapeNamesFromMesh(mi.Mesh);
			if (shapeNames.Count < meshData.MeshShapes.Count)
			{
				if (!MobConstants.ShapelessFiles.Contains(meshData.MeshFile))
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
					? f.ToString(CultureInfo.InvariantCulture)
					: value.ToString() ?? "";
				sp.SetValue(str);
				break;
			case ColorPickerComponent cp when value is Color c: cp.SetValue(c); break;
			case null: GD.Print("Couldn't find " + pickerName + " in " + tabName); break;
		}
	}
}
