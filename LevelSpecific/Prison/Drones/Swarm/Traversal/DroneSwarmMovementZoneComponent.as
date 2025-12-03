class UDroneSwarmMovementZoneComponent : UHazeMovablePlayerTriggerComponent
{
	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter PlayerCharacter) const
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(PlayerCharacter);
		if (SwarmDroneComponent == nullptr)
			return false;

		// if (!SwarmDroneComponent.bSwarmModeActive)
		// 	bPlayerWantsToBeInside = false;

		return true;
	}
}