using CharacterDemo.Mob;
using CharacterDemo.Mob.Scenes.Player;
using CharacterDemo.Mob.Services;
using Godot;
using PlayerCameraManager = CharacterDemo.Mob.Services.PlayerCameraManager;

namespace CharacterDemo.UI.Scenes.Creator.CreatorCameraManager;

/// <summary>
///  Camera manager for Creator
/// </summary>
public partial class CreatorCameraManager : Control
{
	// player variables
	public PlayerCameraManager PlayerCameraManager = null!;
	private CameraService _camera = null!;

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

	public void Initialize(Player player)
	{
		SetupNodes();
		PlayerCameraManager = player.CameraManager;
		_camera = PlayerCameraManager.Camera;
		player.Body.Rotation = Vector3.Zero;
		_camera.Zoom(MobConstants.ZoomInitialCreator - PlayerCameraManager.GetNode<SpringArm3D>("SpringArm3D").SpringLength);
		SetCameraHeightByRace(MobEnums.MobRaces.Human);
		SetupUiSignals();
	}

	public override void _Process(double delta)
	{
		var dt = (float)delta;
		if (_holdRotateDir != Vector2.Zero)
			_camera.Rotate(_holdRotateDir, MobConstants.RotateStepButtonCreator);
		if (_holdZoomDir != 0)
			_camera.Zoom(_holdZoomDir * MobConstants.ZoomStepButtonCreator * dt);
	}

	public override void _Input(InputEvent @event)
	{
		switch (@event)
		{
			case InputEventMouseButton { ButtonIndex: MouseButton.Right } mb:
				_isDragging = mb.Pressed;
				break;

			case InputEventMouseMotion motion when _isDragging:
				_camera.Rotate(-motion.Relative, MobConstants.RotateStepMouseCreator);
				GetViewport().SetInputAsHandled();
				break;

			case InputEventMouseButton { ButtonIndex: MouseButton.WheelUp }:
				_camera.Zoom(-MobConstants.ZoomStepMouseCreator);
				GetViewport().SetInputAsHandled();
				break;

			case InputEventMouseButton { ButtonIndex: MouseButton.WheelDown }:
				_camera.Zoom(MobConstants.ZoomStepMouseCreator);
				GetViewport().SetInputAsHandled();
				break;
		}
	}

	public void SetCameraHeightByRace(MobEnums.MobRaces race)
	{
		var height = MobConstants.RaceCamHeights.TryGetValue(race, out var h) ? h : MobConstants.RaceCamHeightDefault;
		_cameraHeightSlider.Value = height;
		_camera.SetHeight(height);
	}

	// Setup
	private void SetupNodes()
	{
		_cameraHeightSlider = GetNode<VSlider>("HBoxContainer/CameraHeight");
		_zoomInButton = GetNode<Button>("HBoxContainer/VBoxContainer2/Zoom/ZoomIn");
		_zoomOutButton = GetNode<Button>("HBoxContainer/VBoxContainer2/Zoom/ZoomOut");
		_rotateLeftButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/Rotation/RotateLeft");
		_rotateRightButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/Rotation/RotateRight");
		_rotateUpButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/RotateUp");
		_rotateDownButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/RotateDown");
		_rotateResetButton = GetNode<TextureButton>("HBoxContainer/VBoxContainer2/Rotation/Rotation/RotateReset");
	}

	private void SetupUiSignals()
	{
		_cameraHeightSlider.ValueChanged += v => _camera.SetHeight((float)v);
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
		_rotateResetButton.Pressed += _camera.ResetRotation;
	}

	// buttons clicked
	private void CameraZoom(float amount) => _camera.Zoom(amount);
	private void RotateCamera(Vector2 direction, float sensitivity) => _camera.Rotate(direction, sensitivity);
}
