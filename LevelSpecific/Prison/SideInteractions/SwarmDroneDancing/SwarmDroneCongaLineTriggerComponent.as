class USwarmDroneCongaLineTriggerComponent : UHazeMovablePlayerTriggerComponent
{
	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter Player) const
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);
		if (SwarmDroneComponent == nullptr)
			return false;

		if (!SwarmDroneComponent.bSwarmModeActive)
			return false;

		if (!UHazeMovementComponent::Get(Player).IsOnWalkableGround())
			return false;

		return true;
	}
}