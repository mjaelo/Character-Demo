using System;
using System.Linq;
using CharacterDemo.General;
using CharacterDemo.Mobs.Scenes.MobScene;
using Godot;

namespace CharacterDemo.Mobs.Services.ActionManagers;

/// <summary>
/// Handles idle animations (body/face).
/// </summary>
public class IdleManager
{
    public bool PerformingEvent;

    private const float FaceIdleEventProbability = 0.2f;
    private const float BodyIdleEventProbability = 0.08f;
    private const double IdleEventInterval = 4.0;
    public bool IsAlive = true;

    private readonly ActionManager _am;
    private Mob Mob => _am.Mob;

    private enum IdleFaceAnims
    {
        FaceLookAround,
        FaceLookDown,
        FaceBlinking
    }

    private enum IdleBodyAnims
    {
        IdleLookAround,
        IdleStretchArms,
        IdleStretchNeck
    }

    public IdleManager(ActionManager am)
    {
        _am = am;
        CreateIdleEventTimer();
    }

    public void OnAnimationFinished(string animName)
    {
        bool isFaceAnim = Enum.GetNames<IdleFaceAnims>().Any(animName.Contains);
        if (isFaceAnim) _am.FaceBlend = 0;
        PerformingEvent = false;
    }

    // Idle event starter functions
    private async void CreateIdleEventTimer()
    {
        while (GodotObject.IsInstanceValid(Mob) && IsAlive)
        {
            await Mob.ToSignal(Mob.GetTree().CreateTimer(IdleEventInterval), SceneTreeTimer.SignalName.Timeout);
            if (!GodotObject.IsInstanceValid(Mob) || !IsAlive) break;
            if (!PerformingEvent) OnIdleEventTimerTimeout();
        }
    }

    private void OnIdleEventTimerTimeout()
    {
        if (GeneralUtils.CheckRng(FaceIdleEventProbability)) StartFacialIdleEvent();
        if (GeneralUtils.CheckRng(BodyIdleEventProbability)) StartBodyIdleEvent();
    }

    private void StartFacialIdleEvent()
    {
        _am.FaceBlend = 1;
        _am.FaceStateMachine.Travel("Idle");
        _am.FaceIdleStateMachine.Travel(GeneralUtils.PickRandom(Enum.GetValues<IdleFaceAnims>()).ToString());
        PerformingEvent = true;
    }

    private void StartBodyIdleEvent()
    {
        _am.BodyStateMachine.Travel("BodyIdles");
        _am.BodyIdleStateMachine.Travel(GeneralUtils.PickRandom(Enum.GetValues<IdleBodyAnims>()).ToString());
        PerformingEvent = true;
    }
}