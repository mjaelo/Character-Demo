using CharacterDemo.Mob.Services.Controllers;
using Godot;

namespace CharacterDemo.Mob.Scenes.Player;

public partial class Player : Mob.Mob
{
	private CameraController _cameraController = null!;
	private ActionHandler _actionHandler = null!;

	public override void _Ready()
	{
		base._Ready();
		_actionHandler = GetNode<ActionHandler>("ActionHandler");
		_cameraController = GetNode<CameraController>("../Controllers/CameraController");
	}

	public override void _UnhandledInput(InputEvent @event)
	{
		if (@event is InputEventMouse || Input.IsActionPressed("Switch Camera"))
			_cameraController.HandleInput(@event);
	}

	protected override void HandleInput(float delta)
	{
		_actionHandler.MovementController.HandleMovement(delta);
		if (Velocity != Vector3.Zero) RotatePlayerBody();

		foreach (var action in System.Enum.GetNames<ActionHandler.ActionKeys>())
		{
			if (Input.IsActionJustPressed(action)) { _actionHandler.ActionController.OnActionPressed(action); return; }
			if (Input.IsActionJustReleased(action)) return;
		}
		foreach (var action in System.Enum.GetNames<ActionHandler.CombatKeys>())
		{
			if (Input.IsActionJustPressed(action)) { _actionHandler.CombatController.OnActionPressed(action); return; }
			if (Input.IsActionJustReleased(action)) { _actionHandler.CombatController.OnActionReleased(action); return; }
		}
	}

	private void RotatePlayerBody()
	{
		if (Direction == Vector3.Zero || !(CurrentSpeed > 0) || _cameraController.CurrentCamera == _cameraController.Camera1P) return;
		float yaw = Mathf.Atan2(
			_cameraController.GlobalTransform.Basis.Z.X,
			_cameraController.GlobalTransform.Basis.Z.Z);
		GetNode<Node3D>("body").Rotation = new Vector3(0, yaw + Mathf.Pi, 0);
	}
}
