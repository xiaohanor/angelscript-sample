struct FSwarmBotAirTransitionData
{
	float SpiralMultiplier;
}

// Needs to tick before normal transition capability
class USwarmDroneAirTransitionCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmTransitionCapability);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerMovementComponent MovementComponent;

	TArray<FSwarmBotAirTransitionData> PerBotData;

	const float MinDuration = 0.3;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Only handle swarmification case
		if (SwarmDroneComponent.bSwarmModeActive)
			return false;

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if (!MovementComponent.IsInAir())
			return false;

		if (SwarmDroneComponent.IsSwarmTransitionBlocked())
			return false;

		if (SwarmDroneComponent.Player.IsPlayerDead())
			return false;

		if (SwarmDroneComponent.Player.IsPlayerRespawning())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration <= MinDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);
		// USwarmDroneEventHandler::Trigger_OnSwarmLand(Player);
		SwarmDroneComponent.bSwarmModeActive = true;
		SwarmDroneComponent.bSwarmTransitionActive = true;

		// Safety measure
		USwarmDroneEventHandler::Trigger_StopSwarmDroneMovement(Player);
		USwarmDroneEventHandler::Trigger_StopSwarmBotMovement(Player);
		
		if(!SwarmDroneComponent.IsInsideHoverZone())
		{
			USwarmDroneEventHandler::Trigger_StartSwarmBotMovement(Player);
			USwarmDroneEventHandler::Trigger_OnTransformToSwarm(Player);
		}

		MakeBotData();

		SwarmDroneComponent.OnSwarmTransitionStartEvent.Broadcast(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PerBotData.Empty();

		Player.UnblockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);

		SwarmDroneComponent.bSwarmTransitionActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Handle movement stuff in SwarmDroneAirMovementCapability !

		// for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		// {
		// 	ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
		// 	FVector BotToPlayer = Player.ActorLocation - SwarmBot.ActorLocation;

		// 	// Higher value the further back bot is
		// 	float Multiplier = (1 + BotToPlayer.DotProductLinear(Player.ActorForwardVector)) * Math::Square(BotToPlayer.Size()) * 0.05;

		// 	FVector FrameVelocity = BotToPlayer.ConstrainToDirection(Player.ActorForwardVector).GetSafeNormal() * Multiplier;

		// 	// Squeeze bots in
		// 	FrameVelocity += BotToPlayer.ConstrainToDirection(Player.ActorRightVector) * 2.0;

		// 	// Add some random spiraly rotation
		// 	FrameVelocity += BotToPlayer.CrossProduct(Player.MovementWorldUp) * 5.0 * PerBotData[i].SpiralMultiplier; 

		// 	FVector NextLocation = SwarmBot.ActorLocation + FrameVelocity * DeltaTime;
		// 	SwarmBot.SetActorLocation(NextLocation);

		// 	FQuat Rotation = FrameVelocity.ToOrientationQuat();
		// 	SwarmBot.SetActorRotation(Rotation);
		// }
	}

	void MakeBotData()
	{
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			FSwarmBotAirTransitionData BotData;
			BotData.SpiralMultiplier = Math::RandRange(-1.0, 1.0);
			PerBotData.Add(BotData);

			// Get how far behind bot is ?
		}
	}
}