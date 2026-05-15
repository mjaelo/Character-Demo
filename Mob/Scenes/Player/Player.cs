using CharacterDemo.Mob.Services;
using Godot;
using PlayerCameraManager = CharacterDemo.Mob.Services.Camera.PlayerCameraManager;

namespace CharacterDemo.Mob.Scenes.Player;

/// <summary>
/// Player-specific logic: input handling, camera, body rotation.
/// </summary>
public partial class Player : Mob.Mob
{
	public PlayerCameraManager CameraManager = null!;
	public Node3D Body = null!;

	public override void _Ready()
	{
		base._Ready();
		Body = GetNode<Node3D>("body");
		CameraManager = GetNode<PlayerCameraManager>("CameraManager");
	}

	protected override void HandleInput(float delta)
	{
		var inputDir = GetMovementInputDirection();
		var isMoving = inputDir != Vector3.Zero;
		Actions.HandleInput(inputDir, isMoving);
		if (isMoving) RotateBody();
	}

	private Vector3 GetMovementInputDirection()
	{
		var dir = Vector3.Zero;
		if (Input.IsActionPressed("Up")) dir -= CameraManager.GlobalTransform.Basis.Z;
		if (Input.IsActionPressed("Down")) dir += CameraManager.GlobalTransform.Basis.Z;
		if (Input.IsActionPressed("Left")) dir -= CameraManager.GlobalTransform.Basis.X;
		if (Input.IsActionPressed("Right")) dir += CameraManager.GlobalTransform.Basis.X;
		return dir.LengthSquared() > 0 ? dir.Normalized() : dir;
	}
	private void RotateBody()
	{
		if (Direction == Vector3.Zero || !(CurrentSpeed > 0) || CameraManager.CurrentCamera == CameraManager.Camera1P) return;
		float yaw = Mathf.Atan2(
			CameraManager.GlobalTransform.Basis.Z.X,
			CameraManager.GlobalTransform.Basis.Z.Z);
		Body.Rotation = new Vector3(0, yaw + Mathf.Pi, 0);
	}

}
