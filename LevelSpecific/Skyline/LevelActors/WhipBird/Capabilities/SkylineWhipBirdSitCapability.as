class USkylineWhipBirdSitCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineWhipBirdSit");

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
		if (!WhipBird.bIsSitting)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (WhipBird.WhipResponseComp.IsGrabbed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("Sit!", 1.0, FLinearColor::Red);

		WhipBird.BlockCapabilities(n"SkylineWhipBirdMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipBird.bIsSitting = false;

		WhipBird.UnblockCapabilities(n"SkylineWhipBirdMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};