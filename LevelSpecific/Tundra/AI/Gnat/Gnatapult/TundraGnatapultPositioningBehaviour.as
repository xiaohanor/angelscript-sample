class UTundraGnatapultPositioningBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UTundraGnatComponent GnatComp;
	UTundraGnatapultSettings Settings;
	bool bInPosition = false;
	FVector Destination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GnatComp = UTundraGnatComponent::Get(Owner);
		Settings = UTundraGnatapultSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		bInPosition = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bInPosition)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.PositioningDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Destination = GnatComp.HostBody.WorldTransform.TransformPosition(Settings.PositioningOnBodyCenter);
		Destination += Math::GetRandomPointOnCircle_XY() * Settings.PositioningOnBodyRadius;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bInPosition = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TargetComp.IsValidTarget(Game::Mio))
			DestinationComp.RotateTowards(Game::Mio);
		else if (TargetComp.IsValidTarget(Game::Zoe))
			DestinationComp.RotateTowards(Game::Zoe);
		else 
			DestinationComp.RotateInDirection(Owner.ActorForwardVector);

		DestinationComp.MoveTowardsIgnorePathfinding(Destination, Settings.PositioningMoveSpeed);
	}
}
