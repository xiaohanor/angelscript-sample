class USanctuaryLightWormNotSwingingCameraCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		return !Player.IsAnyCapabilityActive(n"Swing");
	}
}