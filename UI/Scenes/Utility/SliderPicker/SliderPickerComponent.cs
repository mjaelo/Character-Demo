using System.Collections.Generic;
using System.Globalization;
using Godot;

namespace CharacterDemo.UI.Scenes.Utility.SliderPicker;

public partial class SliderPickerComponent : HBoxContainer
{
	[Export] public bool Disabled
	{
		get => _disabled;
		set { _disabled = value; UiUtils.DisableEdit(this, value); }
	}
	private bool _disabled;

	private List<string> Values { get; set; } = [];
	public HSlider? Picker { get; private set; }
	private object? _selectedValue;

	[Signal] public delegate void VariableChangedEventHandler(Variant newValue);

	public void Init(IEnumerable<string> values, string header = "")
	{
		Values = [.. values];
		GetNode<Label>("VBoxContainer/Labels/Name").Text = header;
		GetNode<TextureButton>("RandomButton").Pressed += OnRandomButtonPressed;
		if (Values.Count < 2)
		{
			if (Values.Count == 1) OnPickerValueChanged(0); 
			Disabled = true; 
			return;
		}
		Disabled = false;
		Picker = new HSlider { MaxValue = Values.Count - 1 };
		Picker.ValueChanged += OnPickerValueChanged;
		GetNode<VBoxContainer>("VBoxContainer").AddChild(Picker);
		OnPickerValueChanged(0);
	}

	// set value to a picker from outside
	public void SetValue(string value)
	{
		if (Disabled) return;
		int idx = Values.IndexOf(value);
		if (idx >= 0 && Picker != null) Picker.Value = idx;
		else GD.Print(Name + ": " + value + " not found in values");
	}

	private void OnPickerValueChanged(double newIndex)
	{
		var newValue = Values[(int)newIndex];
		if (_selectedValue?.Equals(newValue) == true) return;
		_selectedValue = newValue;
		GetNode<Label>("VBoxContainer/Labels/Value").Text = newValue;
		EmitSignal(SignalName.VariableChanged, Variant.From(newValue));
	}

	private void OnRandomButtonPressed()
	{
		if (Picker == null || Values.Count == 0) { Disabled = true; return; }
		SetValue(Values[GD.RandRange(0, Values.Count - 1)]);
	}
}
