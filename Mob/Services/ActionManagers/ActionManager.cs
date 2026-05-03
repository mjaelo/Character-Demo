using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.Services.ActionManagers;

/// <summary>
/// Central animation and action orchestrator for a mob.
/// </summary>
public class ActionManager
{
    public static readonly Dictionary<string, float> PressSpeedModifiers = new() { ["Roll"] = 2f, ["Attack"] = 0.1f };
    public static readonly Dictionary<string, float> HoldSpeedModifiers = new() { ["Run"] = 3f, ["Block"] = 0.2f };

    public readonly Scenes.Mob.Mob Mob;
    public readonly CombatManager Combat;
    public readonly BodyActionManager BodyAction;
    public readonly MovementManager Movement;
    public readonly IdleManager Idle;

    public readonly AnimationNodeStateMachinePlayback ArmStateMachine,
        BodyStateMachine,
        FaceStateMachine,
        IdleStateMachine,
        ActionStateMachine,
        MovementStateMachine,
        BodyIdleStateMachine,
        AttackStateMachine,
        BlockStateMachine,
        DrawStateMachine,
        FaceIdleStateMachine,
        FaceEmotionStateMachine;

    private readonly AnimationTree _animTree;

    public float ArmBlend
    {
        get => _armBlend;
        set
        {
            _armBlend = value;
            _animTree.CreateTween().TweenProperty(_animTree, "parameters/ArmBlend/blend_amount", value, 0.3);
        }
    }

    public float FaceBlend
    {
        get => (float)_animTree.Get("parameters/FaceBlend/blend_amount");
        set => _animTree.Set("parameters/FaceBlend/blend_amount", value);
    }

    private float _armBlend;

    public ActionManager(Scenes.Mob.Mob mob)
    {
        Mob = mob;
        _animTree = mob.GetNode<AnimationTree>("AnimationTree");

        ArmStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/ArmAnims/playback");
        BodyStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/BodyAnims/playback");
        FaceStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/FaceAnims/playback");
        IdleStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/BodyAnims/Idle/playback");
        ActionStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/BodyAnims/Action/playback");
        MovementStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/BodyAnims/Movement/playback");
        BodyIdleStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/BodyAnims/BodyIdles/playback");
        AttackStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/ArmAnims/Attack/playback");
        BlockStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/ArmAnims/Block/playback");
        DrawStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/ArmAnims/DrawWeapon/playback");
        FaceIdleStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/FaceAnims/Idle/playback");
        FaceEmotionStateMachine = (AnimationNodeStateMachinePlayback)_animTree.Get("parameters/FaceAnims/Emotion/playback");
        _armBlend = (float)_animTree.Get("parameters/ArmBlend/blend_amount");

        Combat = new CombatManager(this);
        BodyAction = new BodyActionManager(this);
        Movement = new MovementManager(this);
        Idle = new IdleManager(this);

        _animTree.AnimationFinished += OnAnimationFinished;
    }

    public void HandleInput(Vector3 inputDir, bool isMoving)
    {
        Movement.UpdateVelocity(inputDir);

        if (BodyAction.CheckActionInput(isMoving)) return;
        if (Combat.CheckCombatInput()) return;

        // show movement or idle animation if no action is activated
        if (isMoving) Movement.HandleMovementAnimation();
        else
        {
            if ("Idle" != BodyStateMachine.GetCurrentNode()) BodyStateMachine.Travel("Idle");
            if ("Idle" != IdleStateMachine.GetCurrentNode()) IdleStateMachine.Travel("Idle");
        }
    }

    public bool IsInputBlocked()
    {
        return !Mob.IsOnFloor() || BodyStateMachine.GetCurrentNode() == "Action" || _armBlend > 0.1f;
    }

    public void HandleFalling(float delta)
    {
        Idle.PerformingEvent = false;
        if (Mob.Velocity.Y < Mob.SpeedLimit)
        {
            var v = Mob.Velocity;
            v.Y -= Mob.Gravity * delta;
            Mob.Velocity = v;
        }

        if (IdleStateMachine.GetCurrentNode() != "Fall")
            IdleStateMachine.Travel("Fall");
    }

    private void OnAnimationFinished(StringName animName)
    {
        string name = animName;
        if (name == "Die")
        {
            Idle.IsAlive = false;
            Mob.SetPhysicsProcess(false);
            Mob.GetNode<CollisionShape3D>("CollisionShape3D").QueueFree();
            return;
        }

        if (name.StartsWith("GeneralAnimations") && Idle.PerformingEvent)
            Idle.OnAnimationFinished(name);
        else if (name.StartsWith("CombatAnimations"))
            Combat.OnAnimationFinished(name);
        else if (name.StartsWith("GeneralAnimations"))
            BodyAction.OnAnimationFinished(name);
    }
}