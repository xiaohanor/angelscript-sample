struct FSwarmBoatCapabilityDeactivationParams
{
	FSwarmBoatBeachingParams BeachingParams;

	bool IsBeaching() const
	{
		return !BeachingParams.ExitImpluse.IsZero();
	}
}

class USwarmBoatCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);

	default CapabilityTags.Add(SwarmDroneTags::SwarmDrone);
	default CapabilityTags.Add(SwarmDroneTags::BoatCapability);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	default DebugCategory = Drone::DebugCategory;

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmBoatComponent SwarmBoatComponent;
	UPlayerMovementComponent MovementComponent;
	USimpleMovementData MoveData;

	USwarmBoatSettings Settings;

	bool bEnterComplete;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		SwarmBoatComponent = UPlayerSwarmBoatComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSimpleMovementData();

		Settings = USwarmBoatSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SwarmDroneComponent.IsInsideFloatZone())
			return false;

		if (Player.IsPlayerDead())
			return false;

		if (SwarmBoatComponent.IsBeaching())
			return false;

		return true;
	}

	// Not sure when or how we deactivate... place volume in level?
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSwarmBoatCapabilityDeactivationParams& DeactivationParams) const
	{
		if (Player.IsPlayerDead())
			return true;

		if (SwarmBoatComponent.IsEnteringRapids())
			return false;

		if (SwarmBoatComponent.IsInRapids())
			return false;

		if (!SwarmDroneComponent.IsInsideFloatZone())
			if (MovementComponent.IsOnWalkableGround())
				return true;

		if (SwarmBoatComponent.IsBeaching())
		{
			DeactivationParams.BeachingParams = SwarmBoatComponent.GetBeachingParams();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);
		Player.BlockCapabilities(DroneCommonTags::DroneMeshRotationCapability, this);
		Player.BlockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);
		Player.BlockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);

		bEnterComplete = false;

		SwarmBoatComponent.bBoatActive = true;

		SwarmDroneComponent.bSwarmModeActive = true;
		SwarmDroneComponent.OnSwarmTransitionStartEvent.Broadcast(true);

		SwarmBoatComponent.InitializeBoat(0.4);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSwarmBoatCapabilityDeactivationParams DeactivationParams)
	{
		SwarmBoatComponent.bBoatActive = false;

		SwarmBoatComponent.DismissBoat();

		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneMeshRotationCapability, this);
		Player.UnblockCapabilities(SwarmDroneTags::SwarmMovementCapability, this);
		Player.UnblockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);

		// Eman TODO: This looks like ass right now.
		// Add a nice formation when beaching
		if (DeactivationParams.IsBeaching())
			Player.SetActorVelocity(DeactivationParams.BeachingParams.ExitImpluse);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;

		if (!SwarmDroneComponent.IsInsideFloatZone() && SwarmBoatComponent.IsBeaching())
			SwarmBoatComponent.ClearBeaching();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		bEnterComplete = ActiveDuration >= Settings.EnterTransitionDuration;
		if (bEnterComplete)
		{

		}
		else
		{
			
		}

		if(MovementComponent.HasAnyValidBlockingImpacts())
			SwarmBoatComponent.DetachMagnetDroneFromBoat();
	}
}