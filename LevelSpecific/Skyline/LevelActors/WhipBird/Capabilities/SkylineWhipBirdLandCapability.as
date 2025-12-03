class USkylineWhipBirdLandCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineWhipBirdMovement");
	default CapabilityTags.Add(n"SkylineWhipBirdLand");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineWhipBird WhipBird;

	FHazeAcceleratedVector AcceleratedVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipBird = Cast<ASkylineWhipBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!CanLand())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WhipBird.HasValidTarget())
			return true;

		if (WhipBird.bIsSitting)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("Land!", 1.0, FLinearColor::Red);

		WhipBird.bIsLanding = true;

		WhipBird.BlockCapabilities(n"SkylineWhipBirdMovement", this);
	
		AcceleratedVector.SnapTo(WhipBird.ActorLocation, WhipBird.ActorVelocity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipBird.bIsLanding = false;

		WhipBird.UnblockCapabilities(n"SkylineWhipBirdMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AcceleratedVector.AccelerateTo(WhipBird.CurrentTarget.WorldLocation, WhipBird.LandTime, DeltaTime);
	
		WhipBird.ActorLocation = AcceleratedVector.Value;
		WhipBird.ActorVelocity = AcceleratedVector.Velocity;

		if (ActiveDuration > WhipBird.LandTime)
			WhipBird.bIsSitting = true;
	}

	bool CanLand() const
	{
		if (WhipBird.bIsSitting)
			return false;

		if (WhipBird.bIsLanding)
			return false;

		if (!WhipBird.HasValidTarget())
			return false;

		if (WhipBird.CurrentTarget.WorldLocation.Distance(WhipBird.ActorLocation) > WhipBird.LandDistance)
			return false;

		return true;
	}
};