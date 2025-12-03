class USkylineBossTankCrusherCapability : USkylineBossTankChildCapability
{
	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);
	default CapabilityTags.Add(SkylineBossTankTags::Attacks::SkylineBossTankAttackCrusher);

	FHazeAcceleratedFloat Speed;

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
		BossTank.SetCrusherActive(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.SetCrusherActive(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
//		Speed.AccelerateTo(BossTank.CrusherSpeed)
	}
}