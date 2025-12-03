class USkylineBossTankHoldFireCapability : USkylineBossTankChildCapability
{
	float HoldFireDuration = 3.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > HoldFireDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BossTank.BlockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackMortar, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackAutoCannon, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackCrusherBlast, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.UnblockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackMortar, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackAutoCannon, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::Attacks::SkylineBossTankAttackCrusherBlast, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}