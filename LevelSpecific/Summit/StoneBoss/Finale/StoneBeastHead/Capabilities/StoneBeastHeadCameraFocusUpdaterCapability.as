class UStoneBeastHeadCameraFocusUpdaterCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(StoneBeastHead::Tags::StoneBeastHeadCameraFocusUpdater);

	default TickGroup = EHazeTickGroup::LastMovement;
	AStoneBeastHead StoneBeast;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		StoneBeast = Cast<AStoneBeastHead>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		StoneBeast.UpdateFocusTargetsLocation(DeltaTime);
	}
};