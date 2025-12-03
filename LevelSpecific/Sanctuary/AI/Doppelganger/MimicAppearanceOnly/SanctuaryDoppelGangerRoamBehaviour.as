class USanctuaryDoppelGangerRoamBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USanctuaryDoppelgangerSettings DoppelSettings;
	USanctuaryDoppelgangerComponent DoppelComp;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DoppelSettings = USanctuaryDoppelgangerSettings::GetSettings(Owner);
		DoppelComp = USanctuaryDoppelgangerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DoppelComp.MimicState != EDoppelgangerMimicState::RandomMove)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (DoppelComp.MimicState != EDoppelgangerMimicState::RandomMove)
			return true;
		return false;
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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Roam!
		AnimComp.RequestFeature(LocomotionFeatureAISanctuaryTags::DoppelgangerMimicMovement, EBasicBehaviourPriority::Low, this);
		DestinationComp.MoveTowards(Destination, DoppelSettings.MatchPositionMaxSpeed);

		if (ActiveDuration > BasicSettings.RoamMaxDuration)
			Cooldown.Set(Math::RandRange(BasicSettings.RoamDestinationPauseMin, BasicSettings.RoamDestinationPauseMax));
	}
}


