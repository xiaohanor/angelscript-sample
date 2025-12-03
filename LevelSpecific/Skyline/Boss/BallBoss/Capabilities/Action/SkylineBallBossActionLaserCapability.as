struct FSkylineBallBossActionLaserData
{
	ESkylineBallBossTopLaserSplineID LaserSpline = ESkylineBallBossTopLaserSplineID::None;
	bool bDash = false;
	bool bShowPanelWhenDone = false;
}

class USkylineBallBossActionLaserCapability : UHazeCapability
{
	FSkylineBallBossActionLaserData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;

	float LaserDuration = 0.0;
	float TickDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
	}

	USkylineBallBossSettings GetSettings() const property
	{
		return Cast<USkylineBallBossSettings>(
			BallBoss.GetSettings(USkylineBallBossSettings)
		);
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossActionLaserData& ActivationParams) const
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
		if (TickDuration >= LaserDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossActionLaserData ActivationParams)
	{
		Params = ActivationParams;
		TickDuration = 0.0;
		BossComp.ContinueLostTime();

		auto LaserSpline = GetLaserSpline(Params.LaserSpline);
		BallBoss.BigLaserActor.SetLaserFollowSpline(LaserSpline);
		LaserDuration = BallBoss.BigLaserActor.GetLaserDuration();

		BallBoss.BigLaserActor.ActivateLaser();
		if (BossComp.bDebugPrintActions)
			Print("SkylineBall boss Laser");
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
		BallBoss.BigLaserActor.DeactivateLaser();
		BossComp.AddLostTime(TickDuration - LaserDuration, true);
		if (!BallBoss.MioIsOnBall() && Params.bShowPanelWhenDone)
			BallBoss.ShowPanel();
	}

	UFUNCTION()
	void PositionDashTo(ESkylineBallBossLocationNode Target)
	{
		FSkylineBallBossPositionActionDashData Data;
		Data.DashTarget = Target;
		BallBoss.ActionsComp.PositionActionQueue.Queue(Data);
	}

	UFUNCTION()
	void PositionIdle(float Duration)
	{
		FSkylineBallBossPositionActionIdleData IdleData;
		IdleData.Duration = Duration;
		BossComp.PositionActionQueue.Queue(IdleData);
	}

	ASkylineBallBossTopLaserSpline GetLaserSpline(ESkylineBallBossTopLaserSplineID SplineID)
	{
		TListedActors<ASkylineBallBossTopLaserSpline> Splines;
		if (Splines.Num() == 0)
			return nullptr;
		for (auto Spline : Splines)
		{
			if (Spline.SplineID == SplineID)
				return Spline;
		}
		return nullptr;
	}
}
