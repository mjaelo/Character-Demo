using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using CharacterDemo.General.Services;
using CharacterDemo.Mob;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.InfoFiles;
using CharacterDemo.UI.InfoFiles;
using Godot;
using ColorPickerComponent = CharacterDemo.UI.Scenes.Utility.ColorPicker.ColorPickerComponent;
using SliderPickerComponent = CharacterDemo.UI.Scenes.Utility.SliderPicker.SliderPickerComponent;

namespace CharacterDemo.UI.Scenes.Creator;

public class TabBuilder(Skeleton3D skeleton, Creator creator)
{
    public TabBar GetCreatorTab(MeshPickerInfo[] pickers, string tabName)
    {
        var tab = new TabBar { Name = tabName };
        var scroll = new ScrollContainer();
        scroll.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        var margin = new MarginContainer
        {
            SizeFlagsHorizontal = Control.SizeFlags.Fill | Control.SizeFlags.Expand,
            SizeFlagsVertical = Control.SizeFlags.Fill | Control.SizeFlags.Expand
        };
        var padding = (int)UiConstants.PickerPadding;
        margin.AddThemeConstantOverride("margin_top", padding);
        margin.AddThemeConstantOverride("margin_bottom", padding);
        margin.AddThemeConstantOverride("margin_left", padding);
        margin.AddThemeConstantOverride("margin_right", padding);
        var vbox = new VBoxContainer
        {
            SizeFlagsHorizontal = Control.SizeFlags.Fill | Control.SizeFlags.Expand,
            SizeFlagsVertical = Control.SizeFlags.Fill | Control.SizeFlags.Expand
        };
        margin.AddChild(vbox);
        scroll.AddChild(margin);
        tab.AddChild(scroll);
        foreach (var info in pickers)
        foreach (var pickerSectionNode in GetMeshPickerSection(info, tabName))
            vbox.AddChild(pickerSectionNode);
        return tab;
    }

    private List<Control> GetMeshPickerSection(MeshPickerInfo info, string tabName)
    {
        var pickers = new List<Control>();
        var meshName = info.MeshName;
        var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
        MobMeshInfo? meshInfo = MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi)
            ? bmi
            : MobConstants.EqMeshesInfo.GetValueOrDefault(meshName);

        if (tabName != "Body") pickers.Add(new Label { Text = meshName });
        if (meshInfo == null) return pickers;

        if (info.HasFilePicker)
            pickers.Add(GetFilePicker(
                meshName,
                FileService.GetFileNames(meshInfo.FileFolder),
                meshInstance,
                meshInfo.FileFolder));


        if (info.ColorPickers?.Count > 0)
            for (int i = 0; i < info.ColorPickers.Count; i++)
                if (info.ColorPickers[i])
                    pickers.Add(GetColorPicker(meshName, meshInfo.Colors, meshInstance, i));


        if (info.HasShapePicker)
            foreach (var shapeInfo in meshInfo.Shapes)
                pickers.Add(GetShapePicker(meshName, shapeInfo.Values, meshInstance, shapeInfo.ShapeName));

        pickers.Add(new Control { CustomMinimumSize = new Vector2(0, UiConstants.PickerPadding) });
        return pickers;
    }

    private SliderPickerComponent GetFilePicker(string meshName, List<string> fileNames, MeshInstance3D? meshInstance,
        string fileFolder)
    {
        var node = (SliderPickerComponent)UiConstants.SliderPickerScene.Instantiate();
        node.Name = meshName;
        var allFiles = fileNames.Contains("empty") ? fileNames : ["empty", ..fileNames];
        node.Init(allFiles, meshName);
        if (meshInstance == null || allFiles.Count < 2)
        {
            node.Disabled = true;
            return node;
        }

        node.VariableChanged += v => OnMeshPickerChanged((string)v, meshInstance, meshName, fileFolder);
        return node;
    }

    private ColorPickerComponent GetColorPicker(string meshName, IReadOnlyDictionary<int, IReadOnlyList<Color>> colorsDict, MeshInstance3D? meshInstance, int materialNr)
    {
        var node = (ColorPickerComponent)UiConstants.ColorPickerScene.Instantiate();
        node.Name = meshName + "Color" + materialNr;
        
        // Get colors for this specific material
        var colors = colorsDict.TryGetValue(materialNr, out var c) ? c : new List<Color> { Colors.White };
        node.Init(colors.ToList(), meshName + " Color " + materialNr);
        
        if (meshInstance == null || colors.Count < 1)
        {
            node.Disabled = true;
            return node;
        }

        node.VariableChanged += col => OnColorPickerChanged(col, meshInstance, meshName, materialNr);
        return node;
    }

    private SliderPickerComponent GetShapePicker(string meshName, IReadOnlyList<float> shapeValues,
        MeshInstance3D? meshInstance, string shapeName)
    {
        var node = (SliderPickerComponent)UiConstants.SliderPickerScene.Instantiate();
        node.Name = shapeName;
        node.Init(shapeValues.Select(v => v.ToString(CultureInfo.InvariantCulture)).ToList(), shapeName);
        if (meshInstance == null || shapeValues.Count < 2 || meshInstance.FindBlendShapeByName(shapeName) < 0)
        {
            node.Disabled = true;
            return node;
        }

        int shapeId = MobUtils.GetShapeNamesFromMesh(meshInstance.Mesh).ToList().IndexOf(shapeName);
        node.VariableChanged += v => OnShapePickerChanged((float)v, meshInstance, meshName, shapeId, shapeName);
        return node;
    }

    //  Callbacks 
    private void OnMeshPickerChanged(string value, MeshInstance3D meshInstance, string meshName, string fileFolder)
    {
        creator.UpdatePrevMobData();
        MeshData? meshData = MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi)
            ? MobUtils.GetBodyDataFieldValue(creator.MobData.BodyData, bmi.FieldName)
            : MobConstants.EqMeshesInfo.TryGetValue(meshName, out var emi)
                ? MobUtils.GetEqDataFieldValue(creator.MobData.EquipmentData, emi.FieldName)
                : null;
        if (meshData == null) return;
        
        meshData.MeshFile = value;
        var color = meshData.MeshColors[MobUtils.GetMainMaterial(meshInstance)];
        
        MobUtils.SetMeshFile(value, meshInstance, fileFolder);
        MobUtils.SetMeshColor(color, meshInstance);
    }

    private void OnColorPickerChanged(Color value, MeshInstance3D meshInstance, string meshName, int materialNr = -1)
    {
        creator.UpdatePrevMobData();
        materialNr = materialNr >= 0 ? materialNr : MobUtils.GetMainMaterial(meshInstance);
        
        if (MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi))
        {
            var meshData = MobUtils.GetBodyDataFieldValue(creator.MobData.BodyData, bmi.FieldName);
            var newColors = meshData.MeshColors.ToList();
            while (newColors.Count <= materialNr) newColors.Add(new Color());
            newColors[materialNr] = value;
            meshData.MeshColors = newColors;
        }
        else if (MobConstants.EqMeshesInfo.TryGetValue(meshName, out var emi))
        {
            var meshData = MobUtils.GetEqDataFieldValue(creator.MobData.EquipmentData, emi.FieldName);
            var newColors = meshData.MeshColors.ToList();
            while (newColors.Count <= materialNr) newColors.Add(new Color());
            newColors[materialNr] = value;
            meshData.MeshColors = newColors;
        }

        MobUtils.SetMeshColor(value, meshInstance, materialNr);
        if (meshName == "Hair") MobUtils.PropagateHairColor(creator.MobData.BodyData, skeleton);
        if (MobConstants.MeshesWithSkin.Contains(meshName) && materialNr == 0)
            MobUtils.PropagateSkinColorData(creator.MobData.EquipmentData, value, skeleton);
    }

    private void OnShapePickerChanged(float value, MeshInstance3D meshInstance, string meshName, int shapeId,
        string shapeName)
    {
        creator.UpdatePrevMobData();
        if (MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi))
        {
            var bodyField = MobUtils.GetBodyDataFieldValue(creator.MobData.BodyData, bmi.FieldName);
            var newShapes = bodyField.MeshShapes.ToList();
            if (newShapes.Count <= shapeId) newShapes.Add(value);
            else newShapes[shapeId] = value;
            bodyField.MeshShapes = newShapes;
        }
        else if (MobConstants.EqMeshesInfo.TryGetValue(meshName, out var emi))
        {
            var eqField = MobUtils.GetEqDataFieldValue(creator.MobData.EquipmentData, emi.FieldName);
            var newShapes = eqField.MeshShapes.ToList();
            if (newShapes.Count <= shapeId) newShapes.Add(value);
            else newShapes[shapeId] = value;
            eqField.MeshShapes = newShapes;
        }

        MobUtils.SetSkeletonShapeKey(value, shapeName, (Skeleton3D)meshInstance.GetParent());
    }
}
