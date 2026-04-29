using Godot;
using CharacterDemo.Mob.Scenes.Player;
using CharacterDemo.UI.Scenes.Creator;

namespace CharacterDemo.General.Scenes.Main;

public partial class Main : Node3D
{
	private Creator _creator = null!;
	private Player _player = null!;
	private Skeleton3D _skeleton = null!;

	public override void _Ready()
	{
		_creator = GetNode<Creator>("Creator");
		_player = GetNode<Player>("Player/Mob");
		_skeleton = GetNode<Skeleton3D>("Player/Mob/body/Armature/Skeleton3D");
		_creator.Initialize(_player, _skeleton);
	}
}
