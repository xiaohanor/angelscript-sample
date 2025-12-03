class USanctuaryBossArenaHydraActionsComponent : UActorComponent
{
	FHazeStructQueue ActionQueue;
	bool bDebugPrintActions = false;
}

asset ArenaHydraActionSelectionSheet of UHazeCapabilitySheet
{
	AddCapability(n"SanctuaryBossArenaHydraSelectActionCapability");

	AddCapability(n"SanctuaryBossArenaHydraActionIdleCapability");
	AddCapability(n"SanctuaryBossArenaHydraActionRainCapability");
	AddCapability(n"SanctuaryBossArenaHydraActionRainDanceCapability");
	AddCapability(n"SanctuaryBossArenaHydraActionWaveCapability");
	AddCapability(n"SanctuaryBossArenaHydraActionWaveDanceCapability");
	AddCapability(n"SanctuaryBossArenaHydraActionProjectileCapability");
};

class USanctuaryBossArenaHydraSelectActionCapability : UHazeCapability
{
	default CapabilityTags.Add(ArenaHydraTags::ArenaHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	ASanctuaryBossArenaHydra Hydra;
	USanctuaryBossArenaHydraActionsComponent BossComp;
	USanctuaryCompanionAviationPlayerComponent MioAviation;
	USanctuaryCompanionAviationPlayerComponent ZoeAviation;

	bool bQueuedSpecialAttack = false;
	bool bShouldDoSpecialAttack = false;
	int ShotProjectiles = 0;

	bool bUseProjectileAttack1 = false;
	bool bUseRainAttack = true;
	bool bDisabledDead = false;
	bool bSpecialCaseRain = false;
	bool bSpecialCaseWave = false;

	UArenaHydraSettings GetSettings() const property
	{
		return Cast<UArenaHydraSettings>(
			Hydra.GetSettings(UArenaHydraSettings)
		);
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Hydra = Cast<ASanctuaryBossArenaHydra>(Owner);
		Hydra.OnArenaBossHeadDiedEvent.AddUFunction(this, n"HeadDied");
		BossComp = USanctuaryBossArenaHydraActionsComponent::GetOrCreate(Owner);
		MioAviation = USanctuaryCompanionAviationPlayerComponent::Get(Game::Mio);
		ZoeAviation = USanctuaryCompanionAviationPlayerComponent::Get(Game::Zoe);
	}

	UFUNCTION()
	void HeadDied(int HeadCount)
	{
		bShouldDoSpecialAttack = true;
		ShotProjectiles = 0;
		bDisabledDead = HeadCount >= CompanionAviation::HeadsToKill;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BossComp.HasControl())
			return false;
		if (bDisabledDead)
			return false;
		if (BossComp.ActionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bDisabledDead)
			return true;
		if (BossComp.ActionQueue.IsEmpty())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bDisabledDead)
			return;

		if (MioAviation == nullptr)
			MioAviation = USanctuaryCompanionAviationPlayerComponent::Get(Game::Mio);
		if (ZoeAviation == nullptr)
			ZoeAviation = USanctuaryCompanionAviationPlayerComponent::Get(Game::Zoe);

		if (SanctuaryHydraDevToggles::NoAttacks.IsEnabled())
			return;

		bool bBothPlayerAviating = MioAviation.GetIsAviationActive() && ZoeAviation.GetIsAviationActive();
		if (bBothPlayerAviating)
			return;

		if(!bSpecialCaseRain && Hydra.KillCount == 2.0)
		{
			if(MioAviation.GetAviationState() == EAviationState::Skydive || ZoeAviation.GetAviationState() == EAviationState::Skydive)
			{
				bSpecialCaseRain = true;
				SpecialAttack();
				return;
			}
		}	

		if(!bSpecialCaseRain && Hydra.KillCount == 2.0)
		{
			bSpecialCaseRain = true;
			SpecialAttack();
			return;
		}	

		if(!bSpecialCaseWave && Hydra.KillCount == 1.0)
		{
			bSpecialCaseWave = true;
			SpecialAttack();
			return;
		}

		bool bAnyPlayerAviating = MioAviation.GetIsAviationActive() || ZoeAviation.GetIsAviationActive();
		if (bAnyPlayerAviating)
			bQueuedSpecialAttack = false;

		bool bSpecialCaseSpecialAttack = !bAnyPlayerAviating && bShouldDoSpecialAttack;
		if (bQueuedSpecialAttack || bSpecialCaseSpecialAttack)
		{
			SpecialAttack();
		}
		else
		{
			if (Hydra.KillCount == 0)
				ShotProjectiles = 0;

			if (ShotProjectiles >= 6)
			{
				ShotProjectiles = 0;
				Idle(0.5);
				bQueuedSpecialAttack = true;
			}
			if (ShotProjectiles >= 1 && Hydra.KillCount == 2)
			{
				ShotProjectiles = 0;
				Idle(2.0);
				bQueuedSpecialAttack = true;				
			}
			else
			{
				FlipFlopProjectile();
			}
		}
	}

	void FlipFlopProjectile()
	{
		Idle(Math::RandRange(1.5, 2.0));
		bUseProjectileAttack1 = !bUseProjectileAttack1;
		ShotProjectiles++;
		if (bUseProjectileAttack1)
			ProjectileAttack1();
		else
			ProjectileAttack2();
	}

	void SpecialAttack()
	{
		bShouldDoSpecialAttack = false;
		bQueuedSpecialAttack = false;
		if (Hydra.KillCount >= 2)
			RainAttack();
		else if (Hydra.KillCount >= 1)
			WaveAttack();
	}

	// ---------
	// Attack sequences

	void WaveAttack()
	{
		WaveDance();
		Wave();
		Idle(6.0);
	}

	void RainAttack()
	{
		RainDance();
		Idle(Settings.RainDelay);
		Rain();
		Idle(Settings.RainRecoverDuration);
	}

	void ProjectileAttack1()
	{
		Projectile(ESanctuaryBossArenaHydraHead::Four);
		Idle(0.5);
		Projectile(ESanctuaryBossArenaHydraHead::Two);
	}

	void ProjectileAttack2()
	{
		Projectile(ESanctuaryBossArenaHydraHead::One);
		Idle(0.5);
		Projectile(ESanctuaryBossArenaHydraHead::Three);
	}

	// ---------
	// Attack parts
	
	void Projectile(ESanctuaryBossArenaHydraHead Head)
	{
		FSanctuaryBossArenaHydraProjectileActionData Data;
		Data.Head = Head;
		BossComp.ActionQueue.Queue(Data);
	}

	void RainDance()
	{
		FSanctuaryBossArenaHydraRainDanceActionData Data;
		BossComp.ActionQueue.Queue(Data);
	}

	void Rain()
	{
		FSanctuaryBossArenaHydraRainActionData Data;
		BossComp.ActionQueue.Queue(Data);
	}

	void WaveDance()
	{
		FSanctuaryBossArenaHydraWaveDanceActionData Data;
		BossComp.ActionQueue.Queue(Data);
	}

	void Wave()
	{
		FSanctuaryBossArenaHydraWaveActionData Data;
		BossComp.ActionQueue.Queue(Data);
	}

	void Idle(float Duration)
	{
		FSanctuaryBossArenaHydraActionIdleData Data;
		Data.Duration = Duration;
		BossComp.ActionQueue.Queue(Data);
	}

#if EDITOR
	UFUNCTION(DevFunction)
	void DevWaveAttack()
	{
		PrintToScreen("Hydra Dev Wave", 3.0, ColorDebug::Magenta);
		BossComp.ActionQueue.Reset();
		WaveAttack();
	}

	UFUNCTION(DevFunction)
	void DevRainAttack()
	{
		PrintToScreen("Hydra Dev Rain", 3.0, ColorDebug::Magenta);
		BossComp.ActionQueue.Reset();
		RainAttack();
	}
#endif

}
