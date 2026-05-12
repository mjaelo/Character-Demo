using System.Collections.Generic;
using Godot;

namespace CharacterDemo.UI.Scenes.Utility.ColorPicker;

public partial class ColorPickerComponent : HBoxContainer
{
	[Export] public bool Disabled
	{
		get => _disabled;
		set { _disabled = value; UiUtils.DisableEdit(this, value); }
	}
	private bool _disabled;

	public List<Color> Values { get; private set; } = [];
	public ColorPickerButton? Picker { get; private set; }
	private Color _selectedValue = Colors.White;

	[Signal] public delegate void VariableChangedEventHandler(Color newValue);

	public void Init(List<Color> values, string header = "")
	{
		Values = values;
		GetNode<Label>("VBoxContainer/Labels/Name").Text = header;
		GetNode<TextureButton>("RandomButton").Pressed += OnRandomButtonPressed;
		if (Values.Count < 1) { Disabled = true; return; }
		Disabled = false;
		Picker = new ColorPickerButton { CustomMinimumSize = new Vector2(0, 20) };
		Picker.ColorChanged += OnPickerValueChanged;
		GetNode<VBoxContainer>("VBoxContainer").AddChild(Picker);
	}

	public void SetValue(Color value)
	{
		if (Disabled || Picker == null) return;
		Picker.Color = value;
		OnPickerValueChanged(value);
	}

	private void OnPickerValueChanged(Color newValue)
	{
		if (_selectedValue == newValue) return;
		_selectedValue = newValue;
		EmitSignal(SignalName.VariableChanged, newValue);
	}

	private void OnRandomButtonPressed()
	{
		if (Picker == null || Values.Count < 1) { Disabled = true; return; }
		SetValue(Values[GD.RandRange(0, Values.Count - 1)]);
	}
}
