class URidingSnakePlayerCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		return Player.IsAnyCapabilityActive(n"SanctuarySnake");
	}
}
