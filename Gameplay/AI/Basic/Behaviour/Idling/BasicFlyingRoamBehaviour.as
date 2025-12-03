
class UBasicFlyingRoamBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	FVector Destination;
	UBasicAIFlightComponent FlightComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlightComp = UBasicAIFlightComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Find a new destination to go to. Will only affect movement, so no need to replicate.
		if (!UNavigationSystemV1::GetRandomReachablePointInRadius(Owner.ActorLocation, Destination, BasicSettings.RoamRadius))
		{
			// Could not find a path position, try with a random location for partial path or roaming without navmesh
			Destination = FRotator(0.0, Owner.ActorRotation.Yaw + Math::RandRange(-180.0, 180.0), 0.0).Vector() * BasicSettings.RoamRadius;
		}

		float MaxHeight = FlightComp.SpawnHeight + BasicSettings.FlyingRoamMaxSpawnHeightOffset;
		float MinHeight = Destination.Z + BasicSettings.FlyingRoamMinHeightAboveGround;
		Destination.Z = Math::RandRange(MinHeight, MaxHeight);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Roam!
		DestinationComp.MoveTowards(Destination, BasicSettings.RoamMoveSpeed);

		// Continue until we get a result or time runs out
		if (DestinationComp.MoveSuccess() || DestinationComp.MoveStopped())
			Cooldown.Set(Math::RandRange(BasicSettings.RoamDestinationPauseMin, BasicSettings.RoamDestinationPauseMax));
		else if (DestinationComp.MoveFailed())
			Cooldown.Set(1.0); // Wait a while then try again
		else if (ActiveDuration > BasicSettings.RoamMaxDuration)
			Cooldown.Set(Math::RandRange(BasicSettings.RoamDestinationPauseMin, BasicSettings.RoamDestinationPauseMax));
	}
}
