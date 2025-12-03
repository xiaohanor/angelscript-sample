struct FSwarmBotAirMoveData
{
	float Magnitude;
	float RadiusMultiplier;
	FVector RandomVector;
}

class USwarmDroneAirMovementCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::SwarmAirMovementCapability);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 95;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerMovementComponent MovementComponent;
	UPlayerSwarmDroneHijackComponent SwarmDroneHijackComponent;

	TArray<FSwarmBotAirMoveData> AirMoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);
		SwarmDroneHijackComponent = UPlayerSwarmDroneHijackComponent::Get(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!MovementComponent.IsInAir())
			return false;

		if (!Player.IsAnyCapabilityActive(SwarmDroneTags::SwarmTransitionCapability))
			return false;

		if (SwarmDroneComponent.IsInsideAnySpecialMovementZone())
			return false;

		// Eman TODO: Maybe check for air time before activating?

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!SwarmDroneComponent.bSwarmModeActive)
			return true;

		if (!MovementComponent.IsInAir())
			return true;

		if (SwarmDroneComponent.IsInsideAnySpecialMovementZone())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Hmm... hold in memory or create on every activation?
		MakeAirMoveData();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AirMoveData.Empty();

		if(!SwarmDroneHijackComponent.IsHijackActive() && !SwarmDroneComponent.IsInsideHoverZone() && SwarmDroneComponent.bSwarmModeActive)
		{
			USwarmDroneEventHandler::Trigger_OnSwarmLand(Player);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Square(Math::Saturate(ActiveDuration / 1.0));

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			FSwarmBotAirMoveData BotData = AirMoveData[i];

			// Get spiraly velocity
			FVector BotToPlayer = Player.ActorLocation - SwarmBot.ActorLocation;
			FVector Direction = BotToPlayer.CrossProduct(BotData.RandomVector).GetSafeNormal();
			FVector Velocity = Direction * BotData.Magnitude * DeltaTime;

			// Get next location and constrain to radius
			FVector NextBotLocation = SwarmBot.ActorLocation + Velocity;
			const float FlyRadius = SwarmDroneComponent.DroneMeshRadius * BotData.RadiusMultiplier;
			float DistanceToPlayer = NextBotLocation.Distance(Player.ActorLocation);
			if (DistanceToPlayer > FlyRadius)
				NextBotLocation += BotToPlayer.GetSafeNormal() * (DistanceToPlayer - FlyRadius) * Alpha;

			// Constrain to same plane over time?
			// FVector HeightOffset = BotToPlayer.ConstrainToDirection(Player.MovementWorldUp);
			// NextBotLocation += HeightOffset * Alpha * 0.33;

			// Get new location and resolve collisions
			NextBotLocation += MovementComponent.Velocity * DeltaTime;

			if (SwarmBot.bSwarmActive)
				ResolveCollisions(SwarmBot, NextBotLocation);

			SwarmBot.SetActorLocation(NextBotLocation);

			FQuat TargetRotation = Velocity.ToOrientationQuat();
			FQuat Rotation = Math::QInterpTo(SwarmBot.ActorQuat, TargetRotation, DeltaTime, 5.0);
			SwarmBot.SetActorRotation(Rotation);
		}
	}

	void ResolveCollisions(const ASwarmBot& SwarmBot, FVector& OutNextBotLocation)
	{
		FHazeTraceSettings Trace = Trace::InitFromPrimitiveComponent(SwarmBot.Collider);
		Trace.IgnorePlayers();
		FHitResultArray HitResults = Trace.QueryTraceMulti(SwarmBot.ActorLocation, OutNextBotLocation);
		for (FHitResult HitResult : HitResults)
		{
			if (!HitResult.bBlockingHit)
				continue;

			if (HitResult.Actor != nullptr && HitResult.Actor.IsA(ASwarmBot))
				continue;

			if (HitResult.bStartPenetrating)
			{
				OutNextBotLocation += HitResult.ImpactNormal * HitResult.PenetrationDepth;
				return;
			}

			// Get collision binormal
			FVector FrameVelocity = OutNextBotLocation - SwarmBot.ActorLocation;
			FVector Horizontal = FrameVelocity.CrossProduct(HitResult.ImpactNormal);
			FVector Binormal = HitResult.ImpactNormal.CrossProduct(Horizontal);

			// Remove spent movement and redirect to binormal
			float DeltaMagnitude = FrameVelocity.Size() - HitResult.Distance;
			OutNextBotLocation = SwarmBot.ActorLocation + Binormal.GetSafeNormal() * DeltaMagnitude;

			// Mäh, just handle 1st case
			return;
		}
	}

	void MakeAirMoveData()
	{
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			FSwarmBotAirMoveData BotData;
			BotData.RandomVector = Math::GetRandomConeDirection(Player.ActorUpVector, PI / 3, PI / 6) * (i % 2 == 0 ? 1.0 : -1.0);
			BotData.RadiusMultiplier = Math::RandRange(1.0, 2.0);
			BotData.Magnitude = Math::RandRange(40.0, 80.0) * BotData.RadiusMultiplier;
			AirMoveData.Add(BotData);
		}
	}
}