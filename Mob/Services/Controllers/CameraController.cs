using System.Collections.Generic;
using CharacterDemo.UI;
using Godot;

namespace CharacterDemo.Mob.Services.Controllers;

public partial class CameraController : Node3D
{
    public Camera3D Camera1P { get; private set; } = null!;
    public Camera3D Camera3P { get; private set; } = null!;
    public Camera3D CurrentCamera { get; private set; } = null!;

    public float Sensitivity { get; set; } = UiConstants.GameCameraSensitivity;

    private Scenes.Mob.Mob _mob = null!;
    private SpringArm3D _arm = null!;
    private readonly Dictionary<string, bool> _headMeshVisibility = new()
    {
        ["Hair"] = true, ["Beard"] = true, ["Brows"] = true,
        ["Eyelashes"] = true, ["Hat"] = true, ["Eyes"] = true
    };

    public override void _Ready()
    {
        _mob = GetNode<Scenes.Mob.Mob>("../../Mob");
        _arm = GetNode<SpringArm3D>("SpringArm3D");
        Camera1P = GetNode<Camera3D>("1PCamera");
        Camera3P = GetNode<Camera3D>("SpringArm3D/3PCamera");
        CurrentCamera = Camera3P;
        Camera3P.Current = true;
    }

    public override void _Process(double delta)
        => GlobalPosition = _mob.GlobalPosition;

    public void HandleInput(InputEvent @event)
    {
        if (Input.IsActionJustPressed("Switch Camera")) SwitchCameras();
        else if (@event is InputEventMouseMotion motion) RotateCamera(motion);
        else if (@event is InputEventMouseButton btn) HandleZoom(btn);
    }

    private void SwitchCameras()
    {
        if (CurrentCamera == Camera3P)
            foreach (var k in _headMeshVisibility.Keys)
                _headMeshVisibility[k] = _mob.GetNode<MeshInstance3D>("body/Armature/Skeleton3D/" + k).Visible;

        CurrentCamera.Current = false;
        CurrentCamera = CurrentCamera == Camera3P ? (Camera3D)Camera1P : Camera3P;
        CurrentCamera.Current = true;

        _mob.Scale += CurrentCamera == Camera3P ? new Vector3(0, -0.15f, 0) : new Vector3(0, 0.15f, 0);
        foreach (var (k, v) in _headMeshVisibility)
            _mob.GetNode<MeshInstance3D>("body/Armature/Skeleton3D/" + k).Visible = CurrentCamera == Camera3P && v;

        _mob.GetNode<Node3D>("body/Armature").Rotation = new Vector3(0, CurrentCamera == Camera1P ? Mathf.Pi : 0, 0);
        _mob.GetNode<Node3D>("body").Rotation = CurrentCamera == Camera1P ? Rotation : Vector3.Zero;
    }

    private void RotateCamera(InputEventMouseMotion @event)
    {
        Rotation = new Vector3(
            Mathf.Clamp(Rotation.X - @event.Relative.Y / 1000f * Sensitivity, -0.9f, 0.5f),
            Rotation.Y - @event.Relative.X / 1000f * Sensitivity,
            0);
        if (CurrentCamera == Camera1P)
            _mob.GetNode<Node3D>("body").Rotation = Rotation;
    }

    private void HandleZoom(InputEventMouseButton @event)
    {
        if (CurrentCamera == Camera3P)
        {
            if (@event.ButtonIndex == MouseButton.WheelDown && _arm.SpringLength < 5)
                _arm.SpringLength += 0.02f * Sensitivity;
            else if (@event.ButtonIndex == MouseButton.WheelUp)
            {
                if (_arm.SpringLength > -1) _arm.SpringLength -= 0.02f * Sensitivity;
                else SwitchCameras();
            }
        }
        else if (CurrentCamera == Camera1P && @event.ButtonIndex == MouseButton.WheelDown)
            SwitchCameras();
    }
}

