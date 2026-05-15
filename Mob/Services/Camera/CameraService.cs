using Godot;

namespace CharacterDemo.Mob.Services.Camera;

/// Shared camera manipulation logic used by both CameraManager (game) and CreatorCameraManager (creator).
public class CameraService(Node3D pivot, SpringArm3D arm, Camera3D camera1P)
{
    public const float RotMinX = -0.9f;
    public const float RotMaxX = 0.5f;

    private Node3D Pivot { get; } = pivot;
    private SpringArm3D Arm { get; } = arm;
    private Camera3D Camera1P { get; } = camera1P;

    public void Rotate(Vector2 direction, float sensitivity)
    {
        Pivot.Rotation = new Vector3(
            Mathf.Clamp(Pivot.Rotation.X + direction.Y * sensitivity, RotMinX, RotMaxX),
            Pivot.Rotation.Y + direction.X * sensitivity,
            0);
    }

    public void ResetRotation() => Pivot.Rotation = Vector3.Zero;

    public void Zoom(float amount)
    {
        var next = Arm.SpringLength + amount;
        if (next >= MobConstants.ZoomMin && next <= MobConstants.ZoomMax)
            Arm.SpringLength = next;
    }

    public void SetHeight(float value)
    {
        var t = Arm.Transform;
        t.Origin = new Vector3(t.Origin.X, value, t.Origin.Z);
        Arm.Transform = t;

        var t1 = Camera1P.Transform;
        t1.Origin = new Vector3(t1.Origin.X, value, t1.Origin.Z);
        Camera1P.Transform = t1;
    }
}

