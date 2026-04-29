using System;
using System.Linq;
using Godot;

namespace CharacterDemo.Mob.Services.Controllers;

public partial class IdleController : Node
{
    public bool PerformingEvent
    {
        get => _performingEvent;
        set
        {
            _performingEvent = value;
            if (_idleTimer == null) return;
            if (value) _idleTimer.Stop();
            else _idleTimer.Start();
        }
    }
    private bool _performingEvent;

    private float _faceIdleProbability = 0.2f;
    private float _bodyIdleProbability = 0.08f;
    private Scenes.Mob.Mob _parent = null!;
    private ActionHandler _parentController = null!;
    private Timer? _idleTimer;

    private enum IdleFaceAnims { FaceLookAround, FaceLookDown, FaceBlinking }
    private enum IdleBodyAnims { IdleLookAround, IdleStretchArms, IdleStretchNeck }

    private static readonly Random Rng = new();

    public override void _Ready()
    {
        _parent = GetNode<Scenes.Mob.Mob>("../../");
        _parentController = GetNode<ActionHandler>("../");
        CallDeferred(MethodName.SetupTimer);
    }

    private void SetupTimer()
    {
        _idleTimer = new Timer();
        _idleTimer.Timeout += HandleIdleEvent;
        AddChild(_idleTimer);
        _idleTimer.Start(2.0);
    }

    private void FacialIdle()
    {
        _parentController.FaceBlend = 1;
        _parentController.FaceStateMachine.Travel("Idle");
        _parentController.FaceIdleStateMachine.Travel(Enum.GetValues<IdleFaceAnims>().PickRandom().ToString());
        PerformingEvent = true;
    }

    private void BodyIdle()
    {
        _parentController.BodyStateMachine.Travel("BodyIdles");
        _parentController.BodyIdleStateMachine.Travel(Enum.GetValues<IdleBodyAnims>().PickRandom().ToString());
        PerformingEvent = true;
    }

    public void HandleIdle(float delta)
    {
        var desiredState = "Idle";
        if (!_parent.IsOnFloor())
        {
            if (_parent.Velocity.Y < _parent.SpeedLimit)
            {
                var v = _parent.Velocity; v.Y -= _parent.Gravity * delta; _parent.Velocity = v;
            }
            desiredState = "Fall";
            PerformingEvent = false;
        }
        if (desiredState != _parentController.IdleStateMachine.GetCurrentNode())
            _parentController.IdleStateMachine.Travel(desiredState);
    }

    private void HandleIdleEvent()
    {
        if (PerformingEvent) return;
        if (Rng.NextDouble() < _faceIdleProbability) FacialIdle();
        if (Rng.NextDouble() < _bodyIdleProbability) BodyIdle();
    }

    public void OnAnimationFinished(string animName)
    {
        bool isFaceAnim = Enum.GetNames<IdleFaceAnims>().Any(animName.Contains);
        if (isFaceAnim) _parentController.FaceBlend = 0;
        PerformingEvent = false;
    }
}

file static class ArrayExtensions
{
    private static readonly System.Random Rng = new();
    public static T PickRandom<T>(this T[] arr) => arr[Rng.Next(arr.Length)];
}

