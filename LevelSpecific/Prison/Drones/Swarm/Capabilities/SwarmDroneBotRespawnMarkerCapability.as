// Blocks bot respawn when capability is blocked
class USwarmDroneBotRespawnMarkerCapability : UHazeMarkerCapability
{
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneRespawnBotMarkerCapability);

	UFUNCTION(BlueprintOverride)
	void OnMarkerBlocked()
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		if (SwarmDroneComponent != nullptr)
		{
			for (auto SwarmBot : SwarmDroneComponent.SwarmBots)
				SwarmBot.ApplyRespawnBlock(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnMarkerUnblocked()
	{
		UPlayerSwarmDroneComponent SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		if (SwarmDroneComponent != nullptr)
		{
			for (auto SwarmBot : SwarmDroneComponent.SwarmBots)
				SwarmBot.ClearRespawnBlock(this);
		}
	}
}