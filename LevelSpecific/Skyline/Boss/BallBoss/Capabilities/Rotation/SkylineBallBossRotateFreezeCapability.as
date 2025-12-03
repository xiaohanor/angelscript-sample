class USkylineBallBossRotateFreezeCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	default CapabilityTags.Add(SkylineBallBossTags::Rotation);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BallBoss.FreezeRotationRequesters.Num() > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return BallBoss.FreezeRotationRequesters.Num() == 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BallBoss.ResetTarget();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.ResetTarget();
	}
}