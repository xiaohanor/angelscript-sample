class USkylineBallBossLaunchMioToStageCapability : USkylineBallBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;
	
	bool bChangedPhase = false;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return BallBoss.GetPhase() == ESkylineBallBossPhase::TopAlignMioToStage;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopAlignMioToStage)
			return false;

		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopShieldShockwave)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FBallBossAlignRotationData AlignData;
		AlignData.PartComp = Game::Mio.RootComponent;
		AlignData.HeightOffset = 1200.0;
		AlignData.bAccelerateAlignTowardsTarget = true;
		AlignData.bUseRandomOffset = false;
		BallBoss.AddRotationTarget(AlignData);
		bChangedPhase = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BallBoss.RemoveRotationTarget(Game::Mio.RootComponent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bChangedPhase && ActiveDuration > Settings.DurationAfterAligningMioToStartShield)
		{
			bChangedPhase = true;
			BallBoss.ChangePhase(ESkylineBallBossPhase::TopShieldShockwave);
		}
	}
}