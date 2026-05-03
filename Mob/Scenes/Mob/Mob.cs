using CharacterDemo.General;
using CharacterDemo.Mob.DataFiles;
using CharacterDemo.Mob.Services.ActionManagers;
using Godot;
using static CharacterDemo.Mob.MobEnums;

namespace CharacterDemo.Mob.Scenes.Mob;

/// <summary>
/// Base class for all mobs (players, NPCs). ActionManager is a plain class instantiated here.
/// No manager nodes needed in the scene tree.
/// </summary>
public partial class Mob : CharacterBody3D
{
	//  Data 
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

	// Action Management
	public ActionManager Actions = null!;

	public override void _Ready()
	{
		Actions = new ActionManager(this);
	}

	public override void _PhysicsProcess(double delta)
	{ 
		if (!IsOnFloor()) Actions.HandleFalling((float)delta);
		else if (Actions.IdleStateMachine.GetCurrentNode() == "Fall") Actions.IdleStateMachine.Travel("Idle");
		
		if (!Actions.IsInputBlocked()) HandleInput((float)delta);
		
		MoveAndSlide();
	}

	protected virtual void HandleInput(float delta) { } // implemented by player

	public void OnWeaponBodyEntered(Node3D body) => Actions.Combat.OnWeaponBodyEntered(body);
}
