class USkylineWhipBirdGrabbedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"SkylineWhipBirdGrabbed");

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
		if (!WhipBird.WhipResponseComp.IsGrabbed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!WhipBird.WhipResponseComp.IsGrabbed())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipBird.bIsSitting = false;

		WhipBird.ClearTarget();

		WhipBird.BlockCapabilities(n"SkylineWhipBirdMovement", this);
		WhipBird.BlockCapabilities(n"SkylineWhipBirdReaction", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WhipBird.UnblockCapabilities(n"SkylineWhipBirdMovement", this);
		WhipBird.UnblockCapabilities(n"SkylineWhipBirdReaction", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{

	}
};