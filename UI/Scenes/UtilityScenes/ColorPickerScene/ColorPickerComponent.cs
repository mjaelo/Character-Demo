using System.Collections.Generic;
using Godot;

namespace CharacterDemo.UI.Scenes.UtilityScenes.ColorPickerScene;

public partial class ColorPickerComponent : HBoxContainer
{
	[Export] public bool Disabled
	{
		get => _disabled;
		set { _disabled = value; UiUtils.DisableEdit(this, value); }
	}
	private bool _disabled;

	private List<Color> _values  = [];
	private ColorPickerButton? _picker; 
	private Color _selectedValue = Colors.White;

	[Signal] public delegate void VariableChangedEventHandler(Color newValue);

	public void Init(List<Color> values, string header = "")
	{
		_values = values;
		GetNode<Label>("VBoxContainer/Labels/Name").Text = header;
		GetNode<TextureButton>("RandomButton").Pressed += OnRandomButtonPressed;
		if (_values.Count < 1) { Disabled = true; return; }
		Disabled = false;
		_picker = new ColorPickerButton { CustomMinimumSize = new Vector2(0, 20) };
		_picker.ColorChanged += v => OnPickerValueChanged(v);
		GetNode<VBoxContainer>("VBoxContainer").AddChild(_picker);
	}

	public void SetValue(Color value,bool recordChange = false)
	{
		if (Disabled || _picker == null) return;
		OnPickerValueChanged(value,recordChange);
		_picker.Color = value;
	}

	private void OnPickerValueChanged(Color newValue, bool recordChange = true)
	{
		if (_selectedValue == newValue) return;
		_selectedValue = newValue;
		if  (recordChange) EmitSignal(SignalName.VariableChanged, newValue);
	}

	private void OnRandomButtonPressed()
	{
		if (_picker == null || _values.Count < 1) { Disabled = true; return; }
		SetValue(_values[GD.RandRange(0, _values.Count - 1)],true);
	}
}
