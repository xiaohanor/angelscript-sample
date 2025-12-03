struct FSkylineBallBossActionIdleData
{
	float Duration;
}

class USkylineBallBossActionIdleCapability : UHazeCapability
{
	FSkylineBallBossActionIdleData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	USkylineBallBossActionsComponent BossComp;

	float TickDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossActionIdleData& ActivationParams) const
	{
		if (BossComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.ActionQueue.IsActive(this))
			return true;
		if (TickDuration >= Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossActionIdleData ActivationParams)
	{
		Params = ActivationParams;
		Params.Duration -= BossComp.ConsumeLostTime();
		TickDuration = 0.0;

		if (BossComp.bDebugPrintActions)
			Print("SkylineBall boss idle");

		// Print(f"Start Idle {Params.Duration} at {Time::GetGameTimeSince(BossComp.PatternStart)}");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TickDuration += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.ActionQueue.Finish(this);
		BossComp.AddLostTime(TickDuration - Params.Duration, true);
		// Print(f"Finish Idle {Params.Duration} at {Time::GetGameTimeSince(BossComp.PatternStart)} with {ActiveDuration=} and {TickDuration=}");
	}
}
