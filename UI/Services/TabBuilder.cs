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

namespace CharacterDemo.UI.Services;

public class TabBuilder(Skeleton3D skeleton, MobData mobData)
{
    public TabBar CreateTab(MeshPickerInfo[] pickers, string tabName)
    {
        var tab = new TabBar { Name = tabName };
        var scroll = new ScrollContainer();
        scroll.SetAnchorsPreset(Control.LayoutPreset.FullRect);
        var vbox = new VBoxContainer
        {
            SizeFlagsHorizontal = Control.SizeFlags.Fill | Control.SizeFlags.Expand,
            SizeFlagsVertical = Control.SizeFlags.Fill | Control.SizeFlags.Expand
        };
        scroll.AddChild(vbox);
        tab.AddChild(scroll);
        foreach (var info in pickers)
            CreatePickersForMesh(info, vbox);
        var style = scroll.GetThemeStylebox("panel")?.Duplicate() as StyleBoxFlat ?? new StyleBoxFlat();
        style.ContentMarginTop = style.ContentMarginBottom =
            style.ContentMarginLeft = style.ContentMarginRight = UiConstants.PickerPadding;
        scroll.AddThemeStyleboxOverride("panel", style);
        return tab;
    }

    private void CreatePickersForMesh(MeshPickerInfo info, VBoxContainer vbox)
    {
        var meshName = info.MeshName;
        var meshInstance = MobUtils.GetMeshFromSkeleton(meshName, skeleton);
        MobMeshInfo? meshInfo = MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi) ? bmi : MobConstants.EqMeshesInfo.GetValueOrDefault(meshName);

        vbox.AddChild(new Label { Text = meshName });
        if (meshInfo == null) return;

        if (info.HasFilePicker)
        {
            var options = FileService.GetFileNames(meshInfo.FileFolder);
            vbox.AddChild(CreateMeshPicker(meshName, options, meshInstance, meshInfo.FileFolder));
        }

        if (info.HasColorPicker) vbox.AddChild(CreateColorPicker(meshName, meshInfo.Colors, meshInstance));
        if (info.HasShapePicker)
            foreach (var shapeInfo in meshInfo.Shapes)
                vbox.AddChild(CreateShapePicker(meshName, shapeInfo.Values, meshInstance, shapeInfo.ShapeName));

        vbox.AddChild(new Control { CustomMinimumSize = new Vector2(0, UiConstants.PickerPadding) });
    }

    private SliderPickerComponent CreateMeshPicker(string meshName, List<string> fileNames, MeshInstance3D? meshInstance, string fileFolder)
    {
        var node = (SliderPickerComponent)UiConstants.SliderPickerScene.Instantiate();
        node.Name = meshName;
        var all = new List<string> { "empty" };
        all.AddRange(fileNames);
        node.Init(all, meshName);
        if (meshInstance == null || all.Count < 2)
        {
            node.Disabled = true;
            return node;
        }

        node.VariableChanged += v => OnMeshPickerChanged((string)v, meshInstance, meshName, fileFolder);
        return node;
    }

    private ColorPickerComponent CreateColorPicker(string meshName, IReadOnlyList<Color> colors, MeshInstance3D? meshInstance)
    {
        var node = (ColorPickerComponent)UiConstants.ColorPickerScene.Instantiate();
        node.Name = meshName + "Color";
        node.Init(colors.ToList(), meshName + " Color");
        if (meshInstance == null || colors.Count < 1)
        {
            node.Disabled = true;
            return node;
        }

        node.VariableChanged += c => OnColorPickerChanged(c, meshInstance, meshName);
        return node;
    }

    private SliderPickerComponent CreateShapePicker(string meshName, IReadOnlyList<float> shapeValues, MeshInstance3D? meshInstance, string shapeName)
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
        if (MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi))
            MobUtils.GetBodyDataFieldValue(mobData.BodyData, bmi.FieldName).MeshFile = value;
        else if (MobConstants.EqMeshesInfo.TryGetValue(meshName, out var emi))
            MobUtils.GetEqDataFieldValue(mobData.EquipmentData, emi.FieldName).MeshFile = value;
        MobUtils.SetMesh(value, meshInstance, fileFolder);
    }

    private void OnColorPickerChanged(Color value, MeshInstance3D meshInstance, string meshName)
    {
        if (MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi))
            MobUtils.GetBodyDataFieldValue(mobData.BodyData, bmi.FieldName).MeshColor = value;
        else if (MobConstants.EqMeshesInfo.TryGetValue(meshName, out var emi))
            MobUtils.GetEqDataFieldValue(mobData.EquipmentData, emi.FieldName).MeshColor = value;
        int nr = meshName == "Body" ? 0 : -1;
        MobUtils.SetMeshColor(value, meshInstance, nr);
        if (meshName == "Hair") MobUtils.PropagateHairColor(mobData.BodyData, skeleton);
    }

    private void OnShapePickerChanged(float value, MeshInstance3D meshInstance, string meshName, int shapeId, string shapeName)
    {
        if (MobConstants.BodyMeshesInfo.TryGetValue(meshName, out var bmi))
        {
            var bodyField = MobUtils.GetBodyDataFieldValue(mobData.BodyData, bmi.FieldName);
            var newShapes = bodyField.MeshShapes.ToList();
            if (newShapes.Count <= shapeId) newShapes.Add(value);
            else newShapes[shapeId] = value;
            bodyField.MeshShapes = newShapes;
        }
        else if (MobConstants.EqMeshesInfo.TryGetValue(meshName, out var emi))
        {
            var eqField = MobUtils.GetEqDataFieldValue(mobData.EquipmentData, emi.FieldName);
            var newShapes = eqField.MeshShapes.ToList();
            if (newShapes.Count <= shapeId) newShapes.Add(value);
            else newShapes[shapeId] = value;
            eqField.MeshShapes = newShapes;
        }

        MobUtils.SetSkeletonShapeKey(value, shapeName, (Skeleton3D)meshInstance.GetParent());
    }
}