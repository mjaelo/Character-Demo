using CharacterDemo.General;
using Godot;

namespace CharacterDemo.Mob.Services.ActionManagers;

/// <summary>
/// Handles movement velocity and animation.
/// </summary>
public class MovementManager(ActionManager am)
{
    private Scenes.Mob.Mob Mob => am.Mob;
    
    public void UpdateVelocity(Vector3 inputDir)
    {
        Mob.Velocity = new Vector3(inputDir.X * Mob.CurrentSpeed, Mob.Velocity.Y, inputDir.Z * Mob.CurrentSpeed);
        Mob.Direction = inputDir;
    }
    
    public void HandleMovementAnimation()
    {
        var isRunning = Input.IsActionPressed("Run");
        am.BodyStateMachine.Travel("Movement");
        
        if (am.Idle.PerformingEvent) // stop idle event
        {
            am.Idle.PerformingEvent = false;
            am.BodyIdleStateMachine.Next();
            am.BodyStateMachine.Start("Movement");
        }

        bool isNormalSpeed = GeneralUtils.FloatEquals(Mob.CurrentSpeed,Mob.NormalSpeed);
        if (isRunning && isNormalSpeed)
        {
            am.MovementStateMachine.Travel("Run");
            Mob.CurrentSpeed = Mob.NormalSpeed * ActionManager.HoldSpeedModifiers["Run"];
            return;
        }
        am.MovementStateMachine.Travel("Walk");
        if (!isNormalSpeed && !isRunning && IsBodyActionRunning()) Mob.CurrentSpeed = Mob.NormalSpeed;
    }

    private bool IsBodyActionRunning() => am.ArmBlend == 0 && am.BodyStateMachine.GetCurrentNode() != "Action";

}