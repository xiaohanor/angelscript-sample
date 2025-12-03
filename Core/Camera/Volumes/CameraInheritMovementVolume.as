class ACameraInheritMovementVolume : APlayerTrigger
{
	void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerEnter(Player);
		
		UCameraInheritMovementSettings::GetSettings(Player).bInheritMovement = true;
	}

	void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		Super::TriggerOnPlayerLeave(Player);
		
		UCameraInheritMovementSettings::GetSettings(Player).bInheritMovement = false;
	}
}