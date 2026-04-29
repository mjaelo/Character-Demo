using System;
using System.Collections.Generic;
using Godot;

namespace CharacterDemo.Mob.Services.Controllers;

public partial class BodyActionController : Node
{
    private Scenes.Mob.Mob _parent = null!;
    private ActionHandler _parentController = null!;

    private record FrameTrigger(float Threshold, float Prev, Action Action);
    private Dictionary<string, FrameTrigger> _frameTriggers = null!;

    public override void _Ready()
    {
        _parent = GetNode<Scenes.Mob.Mob>("../../");
        _parentController = GetNode<ActionHandler>("../");
        _frameTriggers = new()
        {
            ["Jump"] = new(0.5f, 0f, () => { var v = _parent.Velocity; v.Y += _parent.JumpImpulse; _parent.Velocity = v; })
        };
    }

    public void CheckFrame()
    {
        var actionName = _parentController.ActionStateMachine.GetCurrentNode();
        float playPos = _parentController.ActionStateMachine.GetCurrentPlayPosition();
        if (_frameTriggers.TryGetValue(actionName, out var trigger))
        {
            if (trigger.Prev <= trigger.Threshold && trigger.Threshold < playPos)
                trigger.Action();
            _frameTriggers[actionName] = trigger with { Prev = playPos };
        }
    }

    public void OnActionPressed(string actionName)
    {
        if (!_parent.IsOnFloor() || (actionName == "Roll" && _parent.Velocity == Vector3.Zero)) return;
        _parentController.BodyStateMachine.Start("Action");
        _parentController.ActionStateMachine.Travel(actionName);
        if (actionName == "Roll")
            _parent.CurrentSpeed = _parent.NormalSpeed * ActionHandler.PressSpeedModifiers["Roll"];
    }

    public void OnAnimationFinished(string animName)
    {
        var v = _parent.Velocity; v.X = 0; v.Z = 0; _parent.Velocity = v;
        if (animName.Contains("Jump"))
            _parentController.IdleStateMachine.Travel("Fall");
    }
}

