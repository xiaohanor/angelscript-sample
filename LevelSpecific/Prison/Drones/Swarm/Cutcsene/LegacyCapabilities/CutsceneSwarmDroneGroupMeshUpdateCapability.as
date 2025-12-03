class UCutsceneSwarmDroneGroupMeshUpdateCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 200;

	ACutsceneSwarmDrone SwarmDrone;
	UAnimInstanceSwarmBotGroup SwarmGroupAnimInstance;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDrone = Cast<ACutsceneSwarmDrone>(Owner);
		SwarmGroupAnimInstance = Cast<UAnimInstanceSwarmBotGroup>(SwarmDrone.SwarmGroupMeshComponent.AnimInstance);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (SwarmGroupAnimInstance == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for (int i = 0; i < SwarmDrone::TotalBotCount; i++)
		{
			FCutsceneSwarmBotData& SwarmBot = SwarmDrone.SwarmBots[i];
			SwarmBot.AnimData.Transform = SwarmBot.RelativeTransform * SwarmDrone.SwarmGroupMeshComponent.WorldTransform;
			SwarmGroupAnimInstance.SwarmBotInputData.SwarmBotAnimData[i] = SwarmBot.AnimData;
		}
	}
}