using System.Collections.Generic;
using CharacterDemo.Mob;
using CharacterDemo.Mob.Services.Controllers;
using Godot;

namespace CharacterDemo.UI.Scenes.Creator.CreatorCameraManager;

// TODO  have a common CameraManager for both player and Creator?
public partial class CreatorCameraManager : Control
{
	// player variables
	public CameraController PlayerCameraController = null!; // used only for changing camera rotation TODO handle it more elegantly?
	private SpringArm3D _cameraSpring = null!;
	private Camera3D _camera1P = null!;
	private Node3D _playerBody = null!;

	// Creator variables
	private VSlider _cameraHeightSlider = null!;
	private Button _zoomInButton = null!;
	private Button _zoomOutButton = null!;
	private TextureButton _rotateLeftButton = null!;
	private TextureButton _rotateRightButton = null!;
	private TextureButton _rotateUpButton = null!;
	private TextureButton _rotateDownButton = null!;
	private TextureButton _rotateResetButton = null!;

	// process variables
	private bool _isDragging;
	private Vector2 _holdRotateDir;
	private float _holdZoomDir;

	public override void _Ready()
	{
		SetupNodes();
		SetupUiSignals();
	}

	public override void _Process(double delta)
	{
		var dt = (float)delta;
		if (_holdRotateDir != Vector2.Zero)
			RotateCamera(_holdRotateDir, UiConstants.ButtonRotateStep);
		if (_holdZoomDir != 0)
			CameraZoom(_holdZoomDir * UiConstants.ButtonZoomStep * dt);
	}

	public override void _Input(InputEvent @event)
	{
		switch (@event)
		{
			case InputEventMouseButton { ButtonIndex: MouseButton.Right } mb:
				_isDragging = mb.Pressed;
				break;

			case InputEventMouseMotion motion when _isDragging:
				RotateCamera(-motion.Relative, UiConstants.MouseRotateStep);
				GetViewport().SetInputAsHandled();
				break;

			case InputEventMouseButton { ButtonIndex: MouseButton.WheelUp }:
				CameraZoom(-UiConstants.MouseZoomStep);
				GetViewport().SetInputAsHandled();
				break;

			case InputEventMouseButton { ButtonIndex: MouseButton.WheelDown }:
				CameraZoom(UiConstants.MouseZoomStep);
				GetViewport().SetInputAsHandled();
				break;
		}
	}

	public void SetCameraHeightByRace(MobEnums.MobRaces race)
	{
		var height = MobConstants.RaceCamHeights.GetValueOrDefault(race, MobConstants.RaceCamHeightDefault);
		_cameraHeightSlider.Value = height;
		OnCameraHeightSliderChanged(height);
	}

	// Setup
	private void SetupNodes()
	{
		PlayerCameraController = GetNode<CameraController>("../../../Player/Controllers/CameraController");
		_cameraSpring = PlayerCameraController.GetNode<SpringArm3D>("SpringArm3D");
		_camera1P = PlayerCameraController.GetNode<Camera3D>("1PCamera");
		_playerBody = GetNode<Node3D>("../../../Player/Mob/body");

		_cameraHeightSlider = GetNode<VSlider>("HBoxContainer/CameraHeight");
		_zoomInButton = GetNode<Button>("HBoxContainer/VBoxContainer2/Zoom/ZoomIn");
		_zoomOutButton = GetNode<Button>("HBoxContainer/VBoxContainer2/Zoom/ZoomOut");
		_rotateLeftButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/Rotation/RotateLeft");
		_rotateRightButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/Rotation/RotateRight");
		_rotateUpButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/RotateUp");
		_rotateDownButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/RotateDown");
		_rotateResetButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/Rotation/RotateReset");

		_playerBody.Rotation = Vector3.Zero;
		_cameraHeightSlider.MaxValue = UiConstants.CameraMaxHeight; // TODO whats the point of that here?
		SetCameraHeightByRace(MobEnums.MobRaces.Human);
	}

	private void SetupUiSignals()
	{
		_cameraHeightSlider.ValueChanged += OnCameraHeightSliderChanged;
		_zoomInButton.ButtonDown += () => _holdZoomDir = -1f;
		_zoomInButton.ButtonUp += () => _holdZoomDir = 0;
		_zoomOutButton.ButtonDown += () => _holdZoomDir = 1f;
		_zoomOutButton.ButtonUp += () => _holdZoomDir = 0;
		_rotateDownButton.ButtonDown += () => _holdRotateDir = new Vector2(0, 1);
		_rotateDownButton.ButtonUp += () => _holdRotateDir = Vector2.Zero;
		_rotateUpButton.ButtonDown += () => _holdRotateDir = new Vector2(0, -1);
		_rotateUpButton.ButtonUp += () => _holdRotateDir = Vector2.Zero;
		_rotateLeftButton.ButtonDown += () => _holdRotateDir = new Vector2(-1, 0);
		_rotateLeftButton.ButtonUp += () => _holdRotateDir = Vector2.Zero;
		_rotateRightButton.ButtonDown += () => _holdRotateDir = new Vector2(1, 0);
		_rotateRightButton.ButtonUp += () => _holdRotateDir = Vector2.Zero;
		_rotateResetButton.Pressed += () => PlayerCameraController.Rotation = Vector3.Zero;
	}

	// buttons clicked
	private void RotateCamera(Vector2 direction, float sensitivity)
	{
		var rotationX = PlayerCameraController.Rotation.X + direction.Y * sensitivity;
		var rotationY = PlayerCameraController.Rotation.Y + direction.X * sensitivity;
		PlayerCameraController.Rotation = new Vector3(rotationX, rotationY, 0);
	}

	private void CameraZoom(float amount)
	{
		var springLen = _cameraSpring.SpringLength + amount;
		if (springLen is >= UiConstants.ZoomMin and <= UiConstants.ZoomMax) _cameraSpring.SpringLength = springLen;
	}

	private void OnCameraHeightSliderChanged(double value)
	{
		var v = (float)value;
		var springTransform = _cameraSpring.Transform;
		springTransform.Origin = new Vector3(springTransform.Origin.X, v, springTransform.Origin.Z);
		_cameraSpring.Transform = springTransform;

		var cameraTransform = _camera1P.Transform;
		cameraTransform.Origin = new Vector3(cameraTransform.Origin.X, v, cameraTransform.Origin.Z);
		_camera1P.Transform = cameraTransform;
	}
}
