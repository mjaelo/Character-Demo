using System.Collections.Generic;
using CharacterDemo.Mob;
using Godot;

namespace CharacterDemo.UI.Scenes.Creator.CreatorCameraManager;

public partial class CreatorCameraManager : Control
{
	private Node3D _playerCameraController = null!;
	private SpringArm3D _cameraSpring = null!;
	private Camera3D _camera1P = null!;
	private HSlider _cameraHeight = null!;
	private InputEventMouse? _propagatedEvent;

	public override void _Ready()
	{
		_playerCameraController = GetNode<Node3D>("../../../Player/Controllers/CameraController");
		_cameraSpring = GetNode<SpringArm3D>("../../../Player/Controllers/CameraController/SpringArm3D");
		_camera1P = GetNode<Camera3D>("../../../Player/Controllers/CameraController/1PCamera");
		_cameraHeight = GetNode<HSlider>("HBoxContainer/CameraHeight");

		_playerCameraController.Call("set", "sensitivity", UiConstants.CreatorCameraSensitivity);
		GetNode<Node3D>("../../../Player/Mob/body").Rotation = Vector3.Zero;
		_cameraSpring.Transform = _cameraSpring.Transform with
		{
			Origin = _cameraSpring.Transform.Origin + new Vector3(0, 0, UiConstants.CreatorCameraZoomOffset)
		};
		_cameraHeight.MaxValue = UiConstants.CameraMaxHeight;
		_cameraHeight.Value = MobConstants.RaceCamHeights.GetValueOrDefault(MobEnums.MobRaces.Human, MobConstants.RaceCamHeightDefault);
		
	}
	
	public void  SetCameraByRace(MobEnums.MobRaces race)
	{
		_cameraHeight.SetValue(MobConstants.RaceCamHeights.GetValueOrDefault(race, MobConstants.RaceCamHeightDefault));
	}

	public override void _Process(double delta)
	{
		if (_propagatedEvent != null)
			_playerCameraController.Call("HandleInput", _propagatedEvent);
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventMouseButton || @event is InputEventMouseMotion && Input.IsMouseButtonPressed(MouseButton.Right))
			_playerCameraController.Call("HandleInput", @event);
	}

	private void OnCameraHeightValueChanged(float value)
	{
		var origin = _cameraSpring.Transform.Origin;
		origin.Y = value;
		_cameraSpring.Transform = _cameraSpring.Transform with { Origin = origin };
		var origin1Person = _camera1P.Transform.Origin;
		origin1Person.Y = value;
		_camera1P.Transform = _camera1P.Transform with { Origin = origin1Person };
	}

	private void OnRotateResetPressed() => _playerCameraController.Rotation = Vector3.Zero;

	private void OnStartGamePressed()
	{
		_playerCameraController.Call("set", "sensitivity", UiConstants.GameCameraSensitivity);
		MobConstants.RaceCamHeights.GetValueOrDefault(GetParent<Creator>().MobData.Race, MobConstants.RaceCamHeightDefault);
		GetParent<Creator>().StartGame();
	}

	private void OnZoomButtonDown(int buttonId)
	{
		var e = new InputEventMouseButton { ButtonIndex = (MouseButton)buttonId };
		_propagatedEvent = e;
	}

	private void OnRotateButtonDown(Vector2 dir)
	{
		var e = new InputEventMouseMotion { Relative = dir };
		_propagatedEvent = e;
	}

	private void OnCameraButtonUp() => _propagatedEvent = null;
}
