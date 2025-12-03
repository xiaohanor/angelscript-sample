// Capability Sheets Example
// See http://wiki.hazelight.se/Scripting/Capabilities
// (Control+Click) on links to open

/**
 * UHazePlayerCapability classes are only allowed to be placed on players,
 * and automatically exposes a 'Player' property.
 *
 * More player-specific functionality might be exposed through this baseclass in the future.
 */
class UExamplePlayerCapability : UHazePlayerCapability
{
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if (Player.IsMio())
			Print("Active Level Sequence: "+Player.ActiveLevelSequenceActor);
	}
};