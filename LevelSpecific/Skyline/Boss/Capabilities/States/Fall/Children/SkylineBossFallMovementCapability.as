class USkylineBossFallMovementCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossFall);

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.GetPhase() == ESkylineBossPhase::First)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Boss.SetActorLocationAndRotation(FallComp.TargetHorizontalLocation, FallComp.TargetRotation);
		// Boss.HeadPivot.SetWorldRotation(FallComp.TargetRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			AlignWithHub(Boss.MovementQueue[0].ToHub, DeltaTime);
		}
		else
		{
			ApplyCrumbSyncedPosition();
		}
	}
};