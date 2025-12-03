class USkylineBossDeadCompoundCapability : USkylineBossCompoundCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossDead);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Boss.IsStateActive(ESkylineBossState::Dead))
			return true;

		if(Boss.HealthComponent.IsDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.IsStateActive(ESkylineBossState::Dead))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.SetState(ESkylineBossState::Dead);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
	}

	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll();
	}
}