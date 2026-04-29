using Godot;
using CharacterDemo.Mob.Scenes.Player;

namespace CharacterDemo.General.Scenes.World;

public partial class World : Node3D
{
	private void OnArea3DBodyExited(Node3D body)
	{
		if (body is not Player) return;
		GD.Print("\n\nResetting Game\n\n");
		GetTree().ReloadCurrentScene();
	}
}
