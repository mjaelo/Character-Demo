using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.Services.Controllers;

public partial class ActionHandler : Node
{
    public enum CombatKeys { DrawWeapon, Attack, Block }
    public enum MovementKeys { Up, Down, Left, Right, Sprint }
    public enum ActionKeys { Roll, Jump }

    public static readonly Dictionary<string, float> PressSpeedModifiers = new() { ["Roll"] = 2f, ["Attack"] = 0.1f };
    public static readonly Dictionary<string, float> HoldSpeedModifiers = new() { ["Run"] = 3f, ["Block"] = 0.2f };

    private Scenes.Mob.Mob _parent = null!;
    private AnimationTree _animTree = null!;

    public CombatController CombatController { get; private set; } = null!;
    public BodyActionController ActionController { get; private set; } = null!;
    public MovementController MovementController { get; private set; } = null!;
    public IdleController IdleController { get; private set; } = null!;

    public AnimationNodeStateMachinePlayback ArmStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback BodyStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback FaceStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback IdleStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback ActionStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback MovementStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback BodyIdleStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback AttackStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback BlockStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback DrawStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback FaceIdleStateMachine { get; private set; } = null!;
    public AnimationNodeStateMachinePlayback FaceEmotionStateMachine { get; private set; } = null!;

    private float _armBlend;
    public float ArmBlend
    {
        get => _armBlend;
        set
        {
            _armBlend = value;
            CreateTween().TweenProperty(_animTree, "parameters/ArmBlend/blend_amount", value, 0.3);
        }
    }
    public float FaceBlend
    {
        get => (float)_animTree.Get("parameters/FaceBlend/blend_amount");
        set => _animTree.Set("parameters/FaceBlend/blend_amount", value);
    }

    public override void _Ready()
    {
        _parent = GetNode<Scenes.Mob.Mob>("../");
        _animTree = GetNode<AnimationTree>("../AnimationTree");
        CombatController = GetNode<CombatController>("CombatController");
        ActionController = GetNode<BodyActionController>("BodyActionController");
        MovementController = GetNode<MovementController>("MovementController");
        IdleController = GetNode<IdleController>("IdleController");

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
    }

    public void CheckFrame()
    {
        if (BodyStateMachine.GetCurrentNode() == "Action")
            ActionController.CheckFrame();
    }

    private void OnAnimationTreeAnimationFinished(StringName animName)
    {
        string name = animName;
        if (name == "Die") { SetPhysicsProcess(false); return; }
        if (name.StartsWith("GeneralAnimations") && IdleController.PerformingEvent)
            IdleController.OnAnimationFinished(name);
        else if (name.StartsWith("CombatAnimations"))
            CombatController.OnAnimationFinished(name);
        else if (name.StartsWith("GeneralAnimations"))
            ActionController.OnAnimationFinished(name);
    }
}

