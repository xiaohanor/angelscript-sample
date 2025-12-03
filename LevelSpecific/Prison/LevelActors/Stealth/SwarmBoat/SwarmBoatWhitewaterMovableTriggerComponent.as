class USwarmBoatWhitewaterMovableTriggerComponent : UHazeMovablePlayerTriggerComponent
{
	UPROPERTY(Transient)
	AHazePlayerCharacter ActivePlayer = nullptr;

	UFUNCTION(BlueprintOverride)
	bool CanTriggerForPlayer(AHazePlayerCharacter Player) const
	{
		UPlayerSwarmBoatComponent SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Player);
		if (SwarmBoatComponent == nullptr)
			return false;

		if (!SwarmBoatComponent.IsBoatActive())
			return false;

		return true;
	}
}