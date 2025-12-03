struct FSkylineBallBossPositionActionIdleData
{
	float Duration;
}

class USkylineBallBossPositionActionIdleCapability : UHazeCapability
{
	FSkylineBallBossPositionActionIdleData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Position);
	USkylineBallBossActionsComponent BossComp;
	ASkylineBallBoss BallBoss;
	default TickGroup = EHazeTickGroup::Movement;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
		BallBoss = Cast<ASkylineBallBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossPositionActionIdleData& ActivationParams) const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return false;
		if (BossComp.PositionActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.FreezeLocationRequesters.Num() > 0)
			return true;
		if (!BossComp.PositionActionQueue.IsActive(this))
			return true;
		if (ActiveDuration > Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossPositionActionIdleData ActivationParams)
	{
		Params = ActivationParams;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.PositionActionQueue.Finish(this);
	}
}
