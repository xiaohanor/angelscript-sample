class USkylineWhipBirdThrowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineWhipBirdMovement");
	default CapabilityTags.Add(n"SkylineWhipBirdThrow");

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineWhipBird WhipBird;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipBird = Cast<ASkylineWhipBird>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!WhipBird.bIsThrown)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 1.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipBird.BlockCapabilities(n"SkylineWhipBirdGrab", this);
		WhipBird.BlockCapabilities(n"SkylineWhipBirdProximityReaction", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipBird.UnblockCapabilities(n"SkylineWhipBirdGrab", this);
		WhipBird.UnblockCapabilities(n"SkylineWhipBirdProximityReaction", this);

		WhipBird.bIsThrown = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};