class USkylineNotUsingWhip : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		return !Player.IsAnyCapabilityActive(GravityWhipTags::GravityWhipGrab);
	}
}