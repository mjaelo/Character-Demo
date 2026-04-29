using Godot;

namespace CharacterDemo.Mob.Services.Controllers;

public partial class MovementController : Node
{
    private Scenes.Mob.Mob _parent = null!;
    private ActionHandler _parentController = null!;

    public override void _Ready()
    {
        _parent = GetNode<Scenes.Mob.Mob>("../../");
        _parentController = GetNode<ActionHandler>("../");
    }

    public void HandleMovement(float delta)
    {
        HandleInput(delta);
        HandleAnimation();
    }

    private void HandleInput(float delta)
    {
        if (!_parent.IsOnFloor()) { var v = _parent.Velocity; v.Y -= _parent.Gravity * delta; _parent.Velocity = v; }

        var inputDir = Vector3.Zero;
        var cam = _parent.GetNode<Services.Controllers.CameraController>("../Controllers/CameraController");
        if (Input.IsActionPressed("Up")) inputDir -= cam.GlobalTransform.Basis.Z;
        if (Input.IsActionPressed("Down")) inputDir += cam.GlobalTransform.Basis.Z;
        if (Input.IsActionPressed("Left")) inputDir -= cam.GlobalTransform.Basis.X;
        if (Input.IsActionPressed("Right")) inputDir += cam.GlobalTransform.Basis.X;
        if (inputDir.LengthSquared() > 0) inputDir = inputDir.Normalized();

        _parent.Velocity = new Vector3(inputDir.X * _parent.CurrentSpeed, _parent.Velocity.Y, inputDir.Z * _parent.CurrentSpeed);
        _parent.Direction = inputDir;
    }

    private void HandleAnimation()
    {
        if (CanWalk())
        {
            _parentController.BodyStateMachine.Travel("Movement");
            if (_parentController.IdleController.PerformingEvent)
            {
                _parentController.IdleController.PerformingEvent = false;
                _parentController.BodyIdleStateMachine.Next();
                _parentController.BodyStateMachine.Start("Movement");
            }
            if (Input.IsActionPressed("Run") && _parent.CurrentSpeed == _parent.NormalSpeed)
            {
                _parentController.MovementStateMachine.Travel("Run");
                _parent.CurrentSpeed = _parent.NormalSpeed * Services.Controllers.ActionHandler.HoldSpeedModifiers["Run"];
            }
            else _parentController.MovementStateMachine.Travel("Walk");
        }
        else if (!_parentController.IdleController.PerformingEvent)
            _parentController.BodyStateMachine.Travel("Idle");

        if (CanResetSpeed()) _parent.CurrentSpeed = _parent.NormalSpeed;
    }

    private bool CanResetSpeed()
        => !Input.IsActionPressed("Run") && _parentController.ArmBlend == 0
            && _parentController.BodyStateMachine.GetCurrentNode() != "Action"
            && _parent.CurrentSpeed != _parent.NormalSpeed;

    private bool CanWalk()
        => _parent.Direction != Vector3.Zero && _parent.Velocity != Vector3.Zero
            && _parent.IsOnFloor()
            && _parentController.BodyStateMachine.GetCurrentNode() != "Action";
}

