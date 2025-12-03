class USkylineBallBossMioDisableDeathWhileJumpingOffBallBossCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (IsActiveCriteriaMet())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (IsActiveCriteriaMet())
			return false;
		return true;
	}

	bool IsActiveCriteriaMet() const
	{
		if (!Player.IsAnyCapabilityActive(GravityBladeCombatTags::GravityBladeAttack))
			return false;

		if (!HasLastDetonator())
			return false;

		return true;
	}

	bool HasLastDetonator() const
	{
		TListedActors<ASkylineBallBossAttachedDetonator> AttachedDetonators;
		if (AttachedDetonators.Num() == 0)
			return false;
		float AccumulatedFutureDamage = 0.0;
		for (ASkylineBallBossAttachedDetonator Attached : AttachedDetonators)
		{
			AccumulatedFutureDamage += Attached.GetFutureDamage();
		}
		TListedActors<ASkylineBallBoss> BallBosses;
		if (BallBosses.Num() == 0)
			return false;
		ASkylineBallBoss BallBoss = BallBosses.Single;
		// 
		float DamageDone = BallBoss.HealthComp.MaxHealth - BallBoss.HealthComp.CurrentHealth;
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn1)
		{
			DamageDone -= AccumulatedFutureDamage;
			if (DamageDone >= BallBoss.Settings.DamageRequiredToActivateShield)
				return true;
		}
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn2)
		{
			DamageDone -= AccumulatedFutureDamage;
			if (DamageDone + KINDA_SMALL_NUMBER >= BallBoss.Settings.DamageRequiredToBreakEye)
				return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"Death", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SkylineBallBossDevToggles::DebugPrintData.IsEnabled())
			Debug::DrawDebugString(Player.ActorCenterLocation, "DISABLED DEATH");
	}
};