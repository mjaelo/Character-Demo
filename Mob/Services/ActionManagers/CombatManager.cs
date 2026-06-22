using System;
using CharacterDemo.Mob.Scenes.Player;
using CharacterDemo.Mob.Services.Camera;
using Godot;

namespace CharacterDemo.Mob.Services.ActionManagers;

/// <summary>
/// Handles combat actions (draw, attack, block).
/// </summary>
public class CombatManager
{
    private enum CombatKeys
    {
        DrawWeapon,
        Attack,
        Block
    }

    private readonly ActionManager _am;
    private Scenes.Mob.Mob Mob => _am.Mob;

    private readonly Node3D _hipSlot, _backSlot, _rHandSlot, _lHandSlot;
    private readonly MeshInstance3D _sword, _shield;
    private bool _weaponDrawn;

    private Skeleton3D _skeleton;
    private int _spineBoneIdx;
    private PlayerCameraManager? _camMan;

    public CombatManager(ActionManager am)
    {
        _am = am;
        var mob = am.Mob;
        _hipSlot = mob.GetNode<Node3D>("body/Armature/Skeleton3D/Hip/HipContainer");
        _backSlot = mob.GetNode<Node3D>("body/Armature/Skeleton3D/Back/BackContainer");
        _rHandSlot = mob.GetNode<Node3D>("body/Armature/Skeleton3D/Right Hand/HandContainer");
        _lHandSlot = mob.GetNode<Node3D>("body/Armature/Skeleton3D/Left Hand/HandContainer");
        _sword = mob.GetNode<MeshInstance3D>("body/Armature/Skeleton3D/Hip/HipContainer/Sword");
        _shield = mob.GetNode<MeshInstance3D>("body/Armature/Skeleton3D/Back/BackContainer/Shield");


        _skeleton = Mob.GetNode<Skeleton3D>("body/Armature/Skeleton3D");
        _spineBoneIdx = _skeleton.FindBone("mixamorig1_Spine");
        if (Mob is Player) _camMan = Mob.GetNode<PlayerCameraManager>("CameraManager");
    }

    public bool CheckCombatInput()
    {
        if (!_sword.Visible) return false;
        if (Input.IsActionJustReleased("Block"))
        {
            OnBlockReleased();
            return true;
        }

        foreach (var action in Enum.GetNames<CombatKeys>())
        {
            if (!Input.IsActionJustPressed(action)) continue;
            OnActionPressed(action);
            return true;
        }

        return false;
    }

    public void OnAnimationFinished(string animName)
    {
        if (animName.Contains("DrawHip"))
        {
            if (_am.DrawStateMachine.GetCurrentNode() == "ReturnHip" ||
                _am.DrawStateMachine.GetCurrentNode() == "DrawHip")
                MobUtils.AttachItemToBone(_weaponDrawn ? _hipSlot : _rHandSlot, _sword);
            else
            {
                _weaponDrawn = !_weaponDrawn;
                _am.ArmBlend = 0;
            }

            return;
        }

        if (animName.Contains("DrawBack"))
        {
            // first attach shield to correct bone and toggle weapon when whole action is finished.
            if (_am.DrawStateMachine.GetCurrentNode() == "ReturnBack" ||
                _am.DrawStateMachine.GetCurrentNode() == "DrawBack")
                MobUtils.AttachItemToBone(_weaponDrawn ? _backSlot : _lHandSlot, _shield);
            else
            {
                if (_sword.Visible) ExecuteAction(CombatKeys.DrawWeapon, "DrawHip");
                else
                {
                    _weaponDrawn = !_weaponDrawn;
                    _am.ArmBlend = 0;
                }
            }

            return;
        }

        if (animName.Contains("Attack"))
        {
            _skeleton.ClearBonesGlobalPoseOverride(); // reset spine rotation
            _am.ArmBlend = 0;
        }

        Mob.CurrentSpeed = Mob.NormalSpeed;
    }

    public void OnWeaponBodyEntered(Node3D body)
    {
        if (body == Mob || body is not Scenes.Mob.Mob mob || _am.ArmBlend < 1 ||
            !_am.AttackStateMachine.IsPlaying() && !_am.AttackStateMachine.GetCurrentNode().ToString().Contains("Attack")) return;
        mob.Actions.IdleStateMachine.Travel("Die");
        mob.Actions.Idle.IsAlive = false;
    }

    // combat actions
    private void OnActionPressed(string actionName)
    {
        var actionId = Enum.Parse<CombatKeys>(actionName);
        if (!_weaponDrawn)
        {
            ToggleWeaponDrawn();
            return;
        }

        switch (actionId)
        {
            case CombatKeys.Attack:
                Attack();
                break;
            case CombatKeys.Block:
                Block();
                break;
            default:
                ToggleWeaponDrawn();
                break;
        }
    }

    private void ToggleWeaponDrawn() => ExecuteAction(CombatKeys.DrawWeapon, _shield.Visible ? "DrawBack" : "DrawHip");

    private void Attack()
    {
        ExecuteAction(CombatKeys.Attack, "AttackSword");
        Mob.CurrentSpeed = Mob.NormalSpeed * ActionManager.PressSpeedModifiers["Attack"];
    }

    private void Block()
    {
        ExecuteAction(CombatKeys.Block, _shield.Visible ? "BlockShield" : "BlockSword");
        Mob.CurrentSpeed = Mob.NormalSpeed * ActionManager.HoldSpeedModifiers["Block"];
    }

    private void OnBlockReleased()
    {
        if (_am.ArmStateMachine.GetCurrentNode() != "Block") return;
        _skeleton.ClearBonesGlobalPoseOverride(); // reset spine rotation
        _am.ArmStateMachine.Travel("Idle");
        _am.ArmBlend = 0;
        Mob.CurrentSpeed = Mob.NormalSpeed;
    }

    private void ExecuteAction(CombatKeys type, string action)
    {
        _am.ArmBlend = 1;
        _am.ArmStateMachine.Travel(type.ToString());
        var actionStateMachine = type switch
        {
            CombatKeys.Attack => _am.AttackStateMachine,
            CombatKeys.Block => _am.BlockStateMachine,
            _ => _am.DrawStateMachine
        };
        if (type is CombatKeys.Attack or CombatKeys.Block)
        {
            RotateSpineWithCamera();
        }

        actionStateMachine.Travel(action);
    }

    private void RotateSpineWithCamera()
    {
        if (_camMan == null) return;
        var camRot = _camMan.GlobalTransform.Basis.Z;
        _skeleton.SetBoneGlobalPoseOverride(
            _spineBoneIdx,
            new Transform3D(
                new Basis(new Quaternion(Vector3.Right, camRot.Y)),
                _skeleton.GetBoneGlobalPose(_spineBoneIdx).Origin
            ),
            1.0f,
            true
        );
    }
}