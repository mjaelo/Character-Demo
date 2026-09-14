using CharacterDemo.Mobs.Scenes.MobScene;
using Godot;

namespace CharacterDemo.Mobs.Services.ActionManagers;

/// <summary>
/// Handles body actions (jump, roll).
/// </summary>
public class BodyActionManager(ActionManager am)
{
    public bool CheckActionInput(bool isMoving)
    {
        if (Input.IsActionJustPressed("Roll") && isMoving)
        {
            OnRollPressed();
            return true;
        }

        if (Input.IsActionJustPressed("Jump"))
        {
            OnJumpPressed();
            return true;
        }

        return false;
    }

    private Mob Mob => am.Mob;
    private const float JumpTimeout = 0.5f;

    public void OnAnimationFinished(string animName)
    {
        var v = Mob.Velocity;
        v.X = 0;
        v.Z = 0;
        Mob.Velocity = v;
        if (animName.Contains("Jump"))
        {
            am.BodyStateMachine.Start("Idle");
            am.IdleStateMachine.Travel("Fall");
        }
    }

    private void OnRollPressed()
    {
        am.BodyStateMachine.Start("Action");
        am.ActionStateMachine.Travel("Roll");
        Mob.CurrentSpeed = Mob.NormalSpeed * ActionManager.PressSpeedModifiers["Roll"];
    }

    private void OnJumpPressed()
    {
        am.BodyStateMachine.Start("Action");
        am.ActionStateMachine.Travel("Jump");
        ScheduleJumpImpulse();
    }

    private async void ScheduleJumpImpulse()
    {
        await Mob.ToSignal(Mob.GetTree().CreateTimer(JumpTimeout), SceneTreeTimer.SignalName.Timeout);
        if (GodotObject.IsInstanceValid(Mob)) OnJumpTimerTimeout();
    }

    private void OnJumpTimerTimeout()
    {
        var v = Mob.Velocity;
        v.Y += Mob.JumpImpulse;
        Mob.Velocity = v;
    }
}