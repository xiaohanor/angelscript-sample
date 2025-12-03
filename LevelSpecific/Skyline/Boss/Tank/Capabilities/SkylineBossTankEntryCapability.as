class USkylineBossTankEntryCapability : USkylineBossTankChildCapability
{
	bool bHasDoneEntry = false;
	float EntryTime = 3.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bHasDoneEntry)
			return false;

		if (BossTank.AttachParentActor != nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > EntryTime)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bHasDoneEntry = true;
		BossTank.BlockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackMortar, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackAutoCannon, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.UnblockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackMortar, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackAutoCannon, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}