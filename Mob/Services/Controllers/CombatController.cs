using System;
using Godot;

namespace CharacterDemo.Mob.Services.Controllers;

public partial class CombatController : Node
{
    private Scenes.Mob.Mob _parent = null!;
    private ActionHandler _parentController = null!;
    private Node3D _hipSlot = null!, _backSlot = null!, _rHandSlot = null!, _lHandSlot = null!;
    private MeshInstance3D _sword = null!, _shield = null!;
    private bool _weaponDrawn;

    public override void _Ready()
    {
        _parent = GetNode<Scenes.Mob.Mob>("../../");
        _parentController = GetNode<ActionHandler>("../");
        _hipSlot = GetNode<Node3D>("../../body/Armature/Skeleton3D/Hip/HipContainer");
        _backSlot = GetNode<Node3D>("../../body/Armature/Skeleton3D/Back/BackContainer");
        _rHandSlot = GetNode<Node3D>("../../body/Armature/Skeleton3D/Right Hand/HandContainer");
        _lHandSlot = GetNode<Node3D>("../../body/Armature/Skeleton3D/Left Hand/HandContainer");
        _sword = GetNode<MeshInstance3D>("../../body/Armature/Skeleton3D/Hip/HipContainer/Sword");
        _shield = GetNode<MeshInstance3D>("../../body/Armature/Skeleton3D/Back/BackContainer/Shield");
    }

    private void AttachItemToBone(Node3D newSlot, Node3D item)
    {
        if (item == null) return;
        item.GetParent().RemoveChild(item);
        newSlot.AddChild(item);
        item.Position = Vector3.Zero;
        item.RotationDegrees = Vector3.Zero;
    }

    private void ExecuteAction(ActionHandler.CombatKeys type, string action)
    {
        _parentController.ArmBlend = 1;
        _parentController.ArmStateMachine.Travel(type.ToString());
        var sm = type switch
        {
            ActionHandler.CombatKeys.Attack => _parentController.AttackStateMachine,
            ActionHandler.CombatKeys.Block => _parentController.BlockStateMachine,
            _ => _parentController.DrawStateMachine
        };
        sm.Travel(action);
    }

    private void ToggleWeapons()
    {
        if (_sword.Visible) ExecuteAction(ActionHandler.CombatKeys.DrawWeapon, "DrawHip");
        else if (_shield.Visible) ExecuteAction(ActionHandler.CombatKeys.DrawWeapon, "DrawBack");
        else _parentController.ArmBlend = 0;
    }

    private void Block()
    {
        if (_shield.Visible) { ExecuteAction(ActionHandler.CombatKeys.Block, "BlockShield"); _parent.CurrentSpeed = _parent.NormalSpeed * ActionHandler.HoldSpeedModifiers["Block"]; }
        else if (_sword.Visible) { ExecuteAction(ActionHandler.CombatKeys.Block, "BlockSword"); _parent.CurrentSpeed = _parent.NormalSpeed * ActionHandler.HoldSpeedModifiers["Block"]; }
        else _parentController.ArmBlend = 0;
    }

    private void Attack()
    {
        ExecuteAction(ActionHandler.CombatKeys.Attack, "AttackSword");
        _parent.CurrentSpeed = _parent.NormalSpeed * ActionHandler.PressSpeedModifiers["Attack"];
    }

    public void OnActionPressed(string actionName)
    {
        var actionId = Enum.Parse<ActionHandler.CombatKeys>(actionName);
        if (!_weaponDrawn)
        {
            if (actionId == ActionHandler.CombatKeys.Attack && !_sword.Visible) { AttachItemToBone(_rHandSlot, _sword); Attack(); }
            else ToggleWeapons();
        }
        else
        {
            if (actionId == ActionHandler.CombatKeys.Attack) Attack();
            else if (actionId == ActionHandler.CombatKeys.Block) Block();
            else ToggleWeapons();
        }
    }

    public void OnActionReleased(string actionName)
    {
        if (actionName == "Block" && _parentController.ArmStateMachine.GetCurrentNode() == "Block")
        { _parentController.ArmStateMachine.Travel("Idle"); _parentController.ArmBlend = 0; }
    }

    public void OnAnimationFinished(string animName)
    {
        if (animName.Contains("DrawHip"))
        {
            if (_parentController.DrawStateMachine.GetCurrentNode() == "ReturnHip")
                AttachItemToBone(_weaponDrawn ? _hipSlot : _rHandSlot, _sword);
            else { if (_shield.Visible) ExecuteAction(ActionHandler.CombatKeys.DrawWeapon, "PutBack"); else { _weaponDrawn = !_weaponDrawn; _parentController.ArmBlend = 0; } }
        }
        else if (animName.Contains("DrawBack"))
        {
            if (_parentController.DrawStateMachine.GetCurrentNode() == "ReturnBack")
                AttachItemToBone(_weaponDrawn ? _backSlot : _lHandSlot, _shield);
            else { _weaponDrawn = !_weaponDrawn; _parentController.ArmBlend = 0; }
        }
        if (animName.Contains("Attack")) _parentController.ArmBlend = 0;
    }

    private void OnWeaponBodyEntered(Node3D body)
    {
        if (body != _parent && body is Scenes.Mob.Mob mob && _parentController.AttackStateMachine.IsPlaying())
        {
            mob.GetNode<ActionHandler>("ActionHandler").IdleStateMachine.Travel("Die");
            mob.GetNode<CollisionShape3D>("CollisionShape3D").QueueFree();
        }
    }
}

