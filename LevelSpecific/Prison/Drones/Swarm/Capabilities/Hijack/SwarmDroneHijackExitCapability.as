class USwarmDroneHijackExitCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneHijackExitCapability);

	default DebugCategory = Drone::DebugCategory;

	default TickGroup = EHazeTickGroup::Movement;

	UPlayerSwarmDroneComponent PlayerSwarmDroneComponent;
	UPlayerSwarmDroneHijackComponent PlayerSwarmDroneHijackComponent;

	// Maybe variable depending on height? Or just property in hijackable component?
	const float ExitDuration = 0.45;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerSwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		PlayerSwarmDroneHijackComponent = UPlayerSwarmDroneHijackComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PlayerSwarmDroneHijackComponent.IsExitingHijack())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > ExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerSwarmDroneComponent.ApplySwarmTransitionBlock(this);
		Player.BlockCapabilities(SwarmDroneTags::SwarmDroneHijackCapability, this);

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = PlayerSwarmDroneComponent.SwarmBots[i];
			SwarmBot.ApplyRespawnBlock(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerSwarmDroneComponent.ClearSwarmTransitionBlock(this);
		PlayerSwarmDroneHijackComponent.bHijackExit = false;

		PlayerSwarmDroneHijackComponent.CurrentHijackTargetable = nullptr;

		Player.UnblockCapabilities(SwarmDroneTags::SwarmDroneHijackCapability, this);

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = PlayerSwarmDroneComponent.SwarmBots[i];
			SwarmBot.ClearRespawnBlock(this);
		}
	}
}