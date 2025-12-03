struct FSkylineBallBossActionPositionData
{
	ESkylineBallBossLocationNode DashTarget;
	float Duration;
}

class USkylineBallBossActionPositionCapability : UHazeCapability
{
	FSkylineBallBossActionPositionData Params;
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
	bool ShouldActivate(FSkylineBallBossActionPositionData& ActivationParams) const
	{
		if (BossComp.ActionQueue.Start(this, ActivationParams))
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossActionPositionData ActivationParams)
	{
		Params = ActivationParams;
		TickDuration = 0.0;
		BossComp.ContinueLostTime();
		BossComp.PositionActionQueue.Reset();
		if (Params.DashTarget == ESkylineBallBossLocationNode::Unassigned)
		{
			FSkylineBallBossPositionActionIdleData Data;
			Data.Duration = Params.Duration;
			BossComp.PositionActionQueue.Queue(Data);
		}
		else
		{
			FSkylineBallBossPositionActionDashData Data;
			Data.DashTarget = Params.DashTarget;
			Data.Duration = Params.Duration;
			BossComp.PositionActionQueue.Queue(Data);
		}
		if (BossComp.bDebugPrintActions)
			Print("SkylineBall boss change Position");
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
		BossComp.AddLostTime(TickDuration, true);
	}
}
