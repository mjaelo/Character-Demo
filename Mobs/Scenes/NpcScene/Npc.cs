using CharacterDemo.Mobs.Scenes.MobScene;

namespace CharacterDemo.Mobs.Scenes.NpcScene;

/// <summary>
/// NPC-specific logic. Extends Mob for shared body/animation via ActionManager.
/// AI-driven movement and behavior will go here.
/// </summary>
public partial class Npc : Mob
{
	protected override void HandleHoldInput()
	{
		// AI logic will drive movement here in the future.
	}
}
