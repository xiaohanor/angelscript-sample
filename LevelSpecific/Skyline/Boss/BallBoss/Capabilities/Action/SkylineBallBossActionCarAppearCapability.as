struct FSkylineBallBossActionCarAppearData
{
	ESkylineBallBossAttacker Actor;
}

class USkylineBallBossActionCarAppearCapability : UHazeCapability
{
	FSkylineBallBossActionCarAppearData Params;
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);
	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;

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
	bool ShouldActivate(FSkylineBallBossActionCarAppearData& ActivationParams) const
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
	void OnActivated(FSkylineBallBossActionCarAppearData ActivationParams)
	{
		Params = ActivationParams;
		TickDuration = 0.0;
		BossComp.ContinueLostTime();
		// Print(f"Car Appear {Params.Actor :n} at {Time::GetGameTimeSince(BossComp.PatternStart)}");
		if (BossComp.bDebugPrintActions)
			Print("SkylineBall boss CarAppear");
		if (BallBoss.Attackers.Contains(Params.Actor))
		{
			auto SlidingCar = Cast<ASkylineBallBossSlidingCar>(BallBoss.Attackers[Params.Actor]);
			if (SlidingCar != nullptr)
			{
				SlidingCar.Appear();
				FSkylineBallBossAttackEventHandlerParams EventParams;
				EventParams.AttackType = ESkylineBallBossAttackEventHandlerType::CarAppear;
				USkylineBallBossEventHandler::Trigger_Attack(BallBoss, EventParams);
			}
			auto LobCar = Cast<ASkylineBallBossLobbingCar>(BallBoss.Attackers[Params.Actor]);
			if (LobCar != nullptr)
			{
				LobCar.Appear();
				FSkylineBallBossAttackEventHandlerParams EventParams;
				EventParams.AttackType = ESkylineBallBossAttackEventHandlerType::CarAppear;
				USkylineBallBossEventHandler::Trigger_Attack(BallBoss, EventParams);
			}
		}
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
