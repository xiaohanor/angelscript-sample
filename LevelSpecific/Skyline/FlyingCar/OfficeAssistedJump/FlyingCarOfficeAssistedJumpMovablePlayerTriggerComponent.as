class UFlyingCarOfficeAssistedJumpMovablePlayerTriggerComponent : UHazeMovablePlayerTriggerComponent
{
	UPROPERTY(Transient, NotEditable)
	FFlyingCarOfficeAssistedJumpSettings Settings;

	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter Player) const
	{
		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Player);
		if (PilotComponent == nullptr)
			return false;

		if (PilotComponent.Car == nullptr)
			return false;

		UFlyingCarOfficeAssistedJumpComponent AssistedJumpComponent = UFlyingCarOfficeAssistedJumpComponent::Get(PilotComponent.Car);
		if (AssistedJumpComponent == nullptr)
			return false;

		if (AssistedJumpComponent.IsAssistedJumpActive())
			return false;

		// if (Settings.bRequiresManualJump)
		// {
		// 	return PilotComponent.Car.bWasJumpActionStarted;
		// }
		// else
		{
			return true;
		}
	}
}