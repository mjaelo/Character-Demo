using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.Services.Camera;

public partial class PlayerCameraManager : Node3D
{
	public Camera3D Camera1P = null!;
	public Camera3D Camera3P = null!;
	public Camera3D CurrentCamera = null!;
	public CameraService Camera = null!;

	private Scenes.Mob.Mob _mob = null!;
	private SpringArm3D _arm = null!;
	private bool _rmbPressed;
	public bool IsCreatorMode = false;

	private readonly Dictionary<string, bool> _headMeshVisibility = new()
	{
		["Hair"] = true, ["Beard"] = true, ["Brows"] = true,
		["Eyelashes"] = true, ["Hat"] = true, ["Eyes"] = true
	};

	public override void _Ready()
	{
		_mob = GetNode<Scenes.Mob.Mob>("../");
		_arm = GetNode<SpringArm3D>("SpringArm3D");
		Camera1P = GetNode<Camera3D>("1PCamera");
		Camera3P = GetNode<Camera3D>("SpringArm3D/3PCamera");
		CurrentCamera = Camera3P;
		Camera3P.Current = true;
		Camera = new CameraService(this, _arm, Camera1P);
	}

	public override void _Process(double delta) => GlobalPosition = _mob.GlobalPosition;

	public override void _Input(InputEvent @event)
	{
		switch (@event)
		{
			case InputEventKey when Input.IsActionJustPressed("Switch Camera") && !IsCreatorMode:
				SwitchCameras();
				break;

			case InputEventMouseButton { ButtonIndex: MouseButton.Right } mb:
				_rmbPressed = mb.Pressed;
				break;

			case InputEventMouseMotion motion when _rmbPressed || !IsCreatorMode:
				Camera.Rotate(-motion.Relative, MobConstants.RotateStepMouseGame);
				if (CurrentCamera == Camera1P)
					_mob.GetNode<Node3D>("body").Rotation = Rotation;
				GetViewport().SetInputAsHandled();
				break;

			case InputEventMouseButton { ButtonIndex: MouseButton.WheelUp }:
				if (CurrentCamera == Camera3P)
				{
					if (_arm.SpringLength > MobConstants.ZoomMin) Camera.Zoom(-MobConstants.ZoomStepMouseGame);
					else SwitchCameras();
				}

				GetViewport().SetInputAsHandled();
				break;

			case InputEventMouseButton { ButtonIndex: MouseButton.WheelDown }:
				if (CurrentCamera == Camera3P) Camera.Zoom(MobConstants.ZoomStepMouseGame);
				else if (CurrentCamera == Camera1P) SwitchCameras();
				GetViewport().SetInputAsHandled();
				break;
		}
	}

	private void SwitchCameras()
	{
		if (CurrentCamera == Camera3P)
			foreach (var k in _headMeshVisibility.Keys)
				_headMeshVisibility[k] = _mob.GetNode<MeshInstance3D>("body/Armature/Skeleton3D/" + k).Visible;

		CurrentCamera.Current = false;
		CurrentCamera = CurrentCamera == Camera3P ? Camera1P : Camera3P;
		CurrentCamera.Current = true;

		_mob.Scale += CurrentCamera == Camera3P ? new Vector3(0, -0.15f, 0) : new Vector3(0, 0.15f, 0);
		foreach (var (k, v) in _headMeshVisibility)
			_mob.GetNode<MeshInstance3D>("body/Armature/Skeleton3D/" + k).Visible = CurrentCamera == Camera3P && v;

		_mob.GetNode<Node3D>("body/Armature").Rotation = new Vector3(0, CurrentCamera == Camera1P ? Mathf.Pi : 0, 0);
		_mob.GetNode<Node3D>("body").Rotation = CurrentCamera == Camera1P ? Rotation : Vector3.Zero;
	}
}
