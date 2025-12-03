class UFlyingCarOfficeCrashMovablePlayerTriggerComponent : UHazeMovablePlayerTriggerComponent
{
	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter Player) const
	{
		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
		if (PilotComponent == nullptr)
			return false;

		if (PilotComponent.Car == nullptr)
			return false;

		UFlyingCarOfficeCrashComponent OfficeCrashComponent = UFlyingCarOfficeCrashComponent::Get(PilotComponent.Car);
		if (OfficeCrashComponent == nullptr)
			return false;

		// Eman TODO: Verify if we are already crashing hier?
		

		return true;
	}
}