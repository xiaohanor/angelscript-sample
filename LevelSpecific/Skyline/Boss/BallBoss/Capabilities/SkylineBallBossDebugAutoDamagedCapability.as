class USkylineBallBossDebugAutoDamagedCapability : UHazeCapability
{
	default CapabilityTags.Add(SkylineBallBossTags::BallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::BallBossBlockedInCutsceneTag);
	ASkylineBallBoss BallBoss;

	UHazeActionQueueComponent DebugActionComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallBoss = Cast<ASkylineBallBoss>(Owner);
		DebugActionComp = UHazeActionQueueComponent::Create(BallBoss);
		SkylineBallBossDevToggles::PretendThereAreDetonators.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!SkylineBallBossDevToggles::PretendThereAreDetonators.IsEnabled())
			return false;
		if (DeactiveDuration < 0.5)
			return false;
		if (!DebugActionComp.IsEmpty())
			return false;
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn1)
			return true;
		if (BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn2)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DebugActionComp.Empty();
		DebugActionComp.Idle(2.0);
		DebugActionComp.Event(this, n"DamageBoss");
	}

	UFUNCTION()
	private void DamageBoss()
	{
		float Damage = BallBoss.Settings.DetonatorDamage + KINDA_SMALL_NUMBER;
		float DamageDone = BallBoss.HealthComp.MaxHealth - BallBoss.HealthComp.CurrentHealth;
		DamageDone += Damage;
		bool Phase2 = BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn2 || BallBoss.GetPhase() == ESkylineBallBossPhase::TopGrappleFailed2;
		if (Phase2 && DamageDone >= BallBoss.Settings.DamageRequiredToBreakEye)
		{
			Damage = BallBoss.HealthComp.CurrentHealth - BallBoss.Settings.DamageRequiredToBreakEye;
			BallBoss.bRecentlyGotDetonated = true;
			BallBoss.ChangePhase(ESkylineBallBossPhase::TopMioOnEyeBroken);
			BallBoss.BreakEye(true);
		}
		if (Damage > 0.0 && BallBoss.GetPhase() != ESkylineBallBossPhase::TopShieldShockwave)
		{
			BallBoss.bRecentlyGotDetonated = true;
			BallBoss.HealthComp.TakeDamage(Damage, EDamageType::Default, BallBoss);
		}

		bool Phase1 = BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioOn1 || BallBoss.GetPhase() == ESkylineBallBossPhase::TopGrappleFailed1;
		if (Phase1 && DamageDone >= BallBoss.Settings.DamageRequiredToActivateShield)
			BallBoss.ChangePhase(ESkylineBallBossPhase::TopAlignMioToStage);
	}
};