class UIslandPortalPlayerSuckInCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 1;

	UIslandPortalTravelerComponent TravelerComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	FHazeAcceleratedVector AcceleratedLocation;
	AIslandPortal CurrentPortal;
	TArray<AIslandPortal> IgnoredPortals;

	bool bMoveDone = false;

	const float DistanceToTriggerSuckIn = 150.0;
	const float SuckInAcceleration = 1500.0;
	const float DistanceBehindPortalToTarget = 5.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TravelerComp = UIslandPortalTravelerComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		TravelerComp.OnPlayerEnterPortal.AddUFunction(this, n"OnPlayerEnterPortal");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		for(int i = IgnoredPortals.Num() - 1; i >= 0; i--)
		{
			float Dist = GetDistanceToPortal(IgnoredPortals[i]);
			if(Dist > DistanceToTriggerSuckIn + 50.0)
				IgnoredPortals.RemoveAt(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandPortalPlayerSuckInActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(!MoveComp.HasGroundContact())
			return false;

		TArray<AIslandPortal> Portals;
		TravelerComp.GetTrackedPortals(Portals);
		for(AIslandPortal Portal : Portals)
		{
			if(IgnoredPortals.Contains(Portal))
				continue;

			// if(Portal.IsVerticalPortal())
			// 	continue;

			if(GetDistanceToPortal(Portal) < DistanceToTriggerSuckIn)
			{
				Params.Portal = Portal;
				return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bMoveDone)
			return true;

		if(ActiveDuration > 1.0)	
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandPortalPlayerSuckInActivatedParams Params)
	{
		AcceleratedLocation.SnapTo(Player.ActorCenterLocation, Player.ActorVelocity);
		CurrentPortal = Params.Portal;
		bMoveDone = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				FVector PreviousLocation = AcceleratedLocation.Value;
				FVector TargetLocation = CurrentPortal.GetPortalCenter() - CurrentPortal.ActorForwardVector * DistanceBehindPortalToTarget;
				FVector CurrentLocation = AcceleratedLocation.ThrustTo(TargetLocation, SuckInAcceleration, DeltaTime);
				if(CurrentLocation.Equals(TargetLocation))
				{
					CurrentLocation = TargetLocation;
					bMoveDone = true;
				}

				FVector Delta = CurrentLocation - PreviousLocation;
				//Delta = Delta.VectorPlaneProject(CurrentPortal.ActorUpVector);
				Movement.AddDelta(Delta);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);

			if(Player.Mesh.CanRequestLocomotion())
			{
				Player.Mesh.RequestLocomotion(n"AirMovement", this);
			}
		}
	}

	UFUNCTION()
	private void OnPlayerEnterPortal(AHazePlayerCharacter TeleportedActor, AIslandPortal OriginPortal,
	                                 AIslandPortal DestinationPortal)
	{
		IgnoredPortals.AddUnique(OriginPortal);
		IgnoredPortals.AddUnique(DestinationPortal);
	}

	float GetDistanceToPortal(AIslandPortal Portal) const
	{
		FVector PortalCenter = Portal.GetPortalCenter();
		FVector ClosestPlayerLocation;
		Player.CapsuleComponent.GetClosestPointOnCollision(PortalCenter, ClosestPlayerLocation);
		FVector ProjectedPortalToPlayer = (ClosestPlayerLocation - PortalCenter).VectorPlaneProject(Portal.ActorUpVector);
		return ProjectedPortalToPlayer.SizeSquared();
	}
}

struct FIslandPortalPlayerSuckInActivatedParams
{
	AIslandPortal Portal;
}