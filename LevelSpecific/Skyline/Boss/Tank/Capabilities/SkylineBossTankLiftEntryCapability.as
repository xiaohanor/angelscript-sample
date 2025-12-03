class USkylineBossTankLiftEntryCapability : USkylineBossTankChildCapability
{
	bool bHasDetached = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bHasDetached)
			return false;

//		if (BossTank.AttachParentActor == nullptr)
//			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BossTank.AttachParentActor == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankMovement, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankMovement, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
	
		bHasDetached = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}