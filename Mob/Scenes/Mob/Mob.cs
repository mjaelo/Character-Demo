using CharacterDemo.General;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.Services.Controllers;
using Godot;
using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.Scenes.Mob;

public partial class Mob : CharacterBody3D
{
	// MobData
	public string MobName = "";
	public MobRaces Race;
	public MobTypes Type;
	public Gender Gender;
	public BodyData BodyData = new();
	public EquipmentData EquipmentData = new();

	// Movement
	public Vector3 Direction;
	public float CurrentSpeed = GeneralConstants.DefaultSpeed;
	public float NormalSpeed = GeneralConstants.DefaultSpeed;
	public float JumpImpulse = GeneralConstants.DefaultJumpImpulse;
	public float Gravity = GeneralConstants.DefaultGravity;
	public float SpeedLimit = GeneralConstants.DefaultSpeedLimit;

	private ActionHandler _actionHandler = null!;

	public override void _Ready()
	{
		_actionHandler = GetNode<ActionHandler>("ActionHandler");
	}

	public override void _PhysicsProcess(double delta)
	{
		// trigger combat / body action action on a frame
		_actionHandler.CheckFrame();
		_actionHandler.IdleController.HandleIdle((float)delta);
		HandleInput((float)delta);
		MoveAndSlide();
	}

	// Override in Player for player-specific input handling
	protected virtual void HandleInput(float delta) { }
}
