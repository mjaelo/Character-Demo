using CharacterDemo.General;
using CharacterDemo.Mobs.DataFiles;
using CharacterDemo.Mobs.Scenes.PlayerScene;
using CharacterDemo.Mobs.Services.ActionManagers;
using CharacterDemo.UI.Scenes.StatsScene;
using Godot;
using static CharacterDemo.Mobs.MobEnums;

namespace CharacterDemo.Mobs.Scenes.MobScene;

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

	public override void _Ready() { Actions = new ActionManager(this); }

	// Godot docs recommend _input for press and_physics_process for hold
	public override void _Input(InputEvent @event) { if (!Actions.IsInputBlocked()) HandlePressInput(); }

	public override void _PhysicsProcess(double delta)
	{
		if (this is Player)
		{
			GetNode<Stats>("../AnimStats").UpdateStats();
		}
		if (!IsOnFloor()) Actions.HandleFalling((float)delta);
		else if (Actions.IdleStateMachine.GetCurrentNode() == "Fall") Actions.IdleStateMachine.Travel("Idle");

		HandleHoldInput();
		MoveAndSlide();
	}

	protected virtual void HandleHoldInput() { } // implemented by player

	protected virtual void HandlePressInput() { } // implemented by player

	private void OnWeaponBodyEntered(Node3D body) => Actions.Combat.OnWeaponBodyEntered(body);
}
