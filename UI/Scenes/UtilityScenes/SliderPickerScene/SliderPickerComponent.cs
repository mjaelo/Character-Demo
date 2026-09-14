using System.Collections.Generic;
using Godot;

namespace CharacterDemo.UI.Scenes.UtilityScenes.SliderPickerScene;

public partial class SliderPickerComponent : HBoxContainer
{
	[Export] public bool Disabled
	{
		get => _disabled;
		set { _disabled = value; UiUtils.DisableEdit(this, value); }
	}
	private bool _disabled;

	private List<string> _values = [];
	private HSlider? _picker;
	private string? _selectedValue;

	[Signal] public delegate void VariableChangedEventHandler(Variant newValue);

	public void Init(IEnumerable<string> values, string header = "")
	{
		_values = [.. values];
		GetNode<Label>("VBoxContainer/Labels/Name").Text = header;
		GetNode<TextureButton>("RandomButton").Pressed += OnRandomButtonPressed;
		if (_values.Count < 2)
		{
			if (_values.Count == 1) OnPickerValueChanged(0);
			Disabled = true; 
			return;
		}
		Disabled = false;
		_picker = new HSlider { MaxValue = _values.Count - 1 };
		_picker.ValueChanged += v => OnPickerValueChanged(v);
		GetNode<VBoxContainer>("VBoxContainer").AddChild(_picker);
		OnPickerValueChanged(0);
	}

	// set value to a picker from outside
	public void SetValue(string value,bool recordChange = false)
	{
		if (Disabled) return;
		int idx = _values.IndexOf(value);
		if (idx >= 0 && _picker != null)
		{
			OnPickerValueChanged(idx,recordChange);
			_picker.Value = idx;
		}
		else GD.Print(Name + ": " + value + " not found in values");
	}

	public void UpdateValues(IEnumerable<string> values)
	{
		_values = [.. values];
		if (_values.Count < 2)
		{
			Disabled = true;
			if (_values.Count == 1) OnPickerValueChanged(0,false);
			return;
		}
		Disabled = false;
		if (_picker == null)
		{
			_picker = new HSlider { MaxValue = _values.Count - 1 };
			_picker.ValueChanged += v => OnPickerValueChanged(v,false);
			GetNode<VBoxContainer>("VBoxContainer").AddChild(_picker);
		}
		else
		{
			_picker.MaxValue = _values.Count - 1;
			if (_picker.Value > _picker.MaxValue) _picker.Value = 0;
		}
	}

	private void OnPickerValueChanged(double newIndex, bool recordChange = true)
	{
		var newValue = _values[(int)newIndex];
		if (_selectedValue?.Equals(newValue) == true) return;
		_selectedValue = newValue;
		GetNode<Label>("VBoxContainer/Labels/Value").Text = newValue;
		if  (recordChange) EmitSignal(SignalName.VariableChanged, Variant.From(newValue));
	}

	private void OnRandomButtonPressed()
	{
		if (_picker == null || _values.Count == 0) { Disabled = true; return; }
		SetValue(_values[GD.RandRange(0, _values.Count - 1)],true);
	}
}
