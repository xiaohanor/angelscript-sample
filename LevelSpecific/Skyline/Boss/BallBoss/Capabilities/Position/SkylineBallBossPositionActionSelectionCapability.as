
asset SkylineBallBossPositionActionSelectionSheet of UHazeCapabilitySheet
{
	Capabilities.Add(USkylineBallBossPositionActionSelectionCapability);
	Capabilities.Add(USkylineBallBossPositionActionChaseSplineCapability);
	Capabilities.Add(USkylineBallBossPositionActionDashCapability);
	Capabilities.Add(USkylineBallBossPositionActionIdleCapability);
	Capabilities.Add(USkylineBallBossPositionActionLemniscateCapability);
	Capabilities.Add(USkylineBallBossPositionActionBouncyTearOffCapability);
};

class USkylineBallBossPositionActionSelectionCapability : UHazeCapability
{
	FSkylineBallBossActionActivateData Params;
	
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Position);
	default CapabilityTags.Add(SkylineBallBossTags::PositionSelection);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);

	ASkylineBallBoss BallBoss;
	USkylineBallBossActionsComponent BossComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		BossComp = USkylineBallBossActionsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BossComp.PositionActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossComp.PositionActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (BallBoss.ChangedPhaseDramaticPauseTimestamp > KINDA_SMALL_NUMBER)
			return;

		switch(BallBoss.GetPhase())
		{
			case ESkylineBallBossPhase::Chase:
			case ESkylineBallBossPhase::PostChaseElevator:
			{
				Chase();
				break;
			} 
			// case ESkylineBallBossPhase::Top: break;
			// case ESkylineBallBossPhase::TopGrappleFailed1: break;
			// case ESkylineBallBossPhase::TopMioOn1: break;
			// case ESkylineBallBossPhase::TopAlignMioToStage: break;
			// case ESkylineBallBossPhase::TopShieldShockwave: break;
			// case ESkylineBallBossPhase::TopMioOff2: break;
			// case ESkylineBallBossPhase::TopGrappleFailed2: break;
			// case ESkylineBallBossPhase::TopMioOn2: break;
			// case ESkylineBallBossPhase::TopMioOnEyeBroken: break;
			// case ESkylineBallBossPhase::TopMioIn: break;
			// case ESkylineBallBossPhase::TopDeath: break;
			default: 
			{
				// we queue in the attacks instead
				break;
			}
		}
	}

	// ---------------------

	private void RandomBehavior()
	{
		// Dash();
		// Dash();
		// LemniscateDash();
		// Dash();
		// Dash();
		// LemniscateDash();
	}

	// ---------------------
	
	private void Chase()
	{
		FSkylineBallBossPositionActionChaseSplineData Data;
		BossComp.PositionActionQueue.Queue(Data);
	}

	// private void Dash()
	// {
	// 	FSkylineBallBossPositionActionDashData Data;
	// 	Data.DashTarget = 
	// 	BossComp.PositionActionQueue.Queue(Data);
	// }

	private void LemniscateDash()
	{
		FSkylineBallBossPositionActionLemniscateData Data;
		Data.DashDuration = 4.0;
		Data.StayDuration = 10.0;
		Data.LemniscateLoopDuration = Math::RandRange(3.0, 6.0);
		BossComp.PositionActionQueue.Queue(Data);
	}
}