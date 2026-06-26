using CharacterDemo.Mob.Scenes.Player;
using Godot;

namespace CharacterDemo.UI.Scenes.Stats;

public partial class Stats : Control
{
	private Player _player = null!;
	private Label _label = null!;
	public override void _Ready()
	{
		_player = GetNode<Player>("../Player");
		_label = GetNode<Label>("Panel/Label");
	}
	
	public void UpdateStats()
	{
		var movementInfo = $"Speed: {_player.CurrentSpeed} / {_player.NormalSpeed}\n" +
			$"Direction: ({_player.Direction.X:F1}, {_player.Direction.Y:F1}, {_player.Direction.Z:F1})\n" +
			$"On Floor: {_player.IsOnFloor()}\n";
		var actionMan = _player.Actions;
		var animationInfo = $"ArmStateMachine: {actionMan.ArmStateMachine.GetCurrentNode()}\n" +
							$"BodyStateMachine: {actionMan.BodyStateMachine.GetCurrentNode()}\n" +
							$"FaceStateMachine: {actionMan.FaceStateMachine.GetCurrentNode()}\n" +
							$"IdleStateMachine: {actionMan.IdleStateMachine.GetCurrentNode()}\n" +
							$"ActionStateMachine: {actionMan.ActionStateMachine.GetCurrentNode()}\n" +
							$"MovementStateMachine: {actionMan.MovementStateMachine.GetCurrentNode()}\n";
							 
		_label.Text = movementInfo+"\n_______________\n\n"+animationInfo;
	}

}