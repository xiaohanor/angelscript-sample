// Capability Sheets Example
// See http://wiki.hazelight.se/Scripting/Capabilities
// (Control+Click) on links to open

/**
 * An example of how to structure a vehicle that starts a capability sheet
 * when the player mounts it.
 */
class AExample_MountedVehicleWithSheet : AHazeActor
{
	/**
	 * The Request Capability On Player Component has an array called 'InitialStoppedSheets'
	 * This property should be filled out in a blueprint subclass to point to the correct sheet.
	 */
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	void OnPlayerMounted(AHazePlayerCharacter Player)
	{
		RequestComp.StartInitialSheetsAndCapabilities(Player, Instigator = this);
	}

	void OnPlayerDismounted(AHazePlayerCharacter Player)
	{
		RequestComp.StopInitialSheetsAndCapabilities(Player, Instigator = this);
	}
};

/**
 * It is also possible to start / stop a sheet directly, but make sure
 * that it is requested by the level blueprint in that case.
 * 
 * It is _NOT_ possible to start a sheet that hasn't been previously
 * requested either by the level blueprint or with a UHazeRequestCapabilityOnPlayerComponent.
 * Attempting this will give you an error message.
 */
 class AExample_StartSheetRequestedByLevel : AHazeActor
 {
	UPROPERTY()
	UHazeCapabilitySheet SheetRequestedByLevel;

	void OnPlayerStartedSection(AHazePlayerCharacter Player)
	{
		Player.StartCapabilitySheet(SheetRequestedByLevel, Instigator = this);
	}

	void OnPlayerFinishedSection(AHazePlayerCharacter Player)
	{
		Player.StopCapabilitySheet(SheetRequestedByLevel, Instigator = this);
	}
 };