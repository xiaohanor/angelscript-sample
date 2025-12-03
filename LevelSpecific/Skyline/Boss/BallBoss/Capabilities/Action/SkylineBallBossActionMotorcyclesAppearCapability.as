
struct FSkylineBallBossActionMotorcyclesAppearData
{
}

class USkylineBallBossActionMotorcyclesAppearCapability : UHazeCapability
{
	FSkylineBallBossActionMotorcyclesAppearData Params;
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
	bool ShouldActivate(FSkylineBallBossActionMotorcyclesAppearData& ActivationParams) const
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
	void OnActivated(FSkylineBallBossActionMotorcyclesAppearData ActivationParams)
	{
		Params = ActivationParams;
		TickDuration = 0.0;
		BossComp.ContinueLostTime();
		Print("SkylineBall boss MotorcyclesAppear");
		for (auto KeyVal : BallBoss.Attackers)
		{
			ASkylineBallBossMotorcycle Bike = Cast<ASkylineBallBossMotorcycle>(KeyVal.Value);
			if (Bike != nullptr)
				Bike.Appear();
		}

		FSkylineBallBossAttackEventHandlerParams EventParams;
		EventParams.AttackType = ESkylineBallBossAttackEventHandlerType::MotorcyclesAppear;
		USkylineBallBossEventHandler::Trigger_Attack(BallBoss, EventParams);
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

	UFUNCTION()
	private void PositionIdle(float Duration)
	{
		FSkylineBallBossPositionActionIdleData IdleData;
		IdleData.Duration = Duration;
		BossComp.PositionActionQueue.Queue(IdleData);
	}

}
