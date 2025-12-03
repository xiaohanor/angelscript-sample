class ASanctuaryBossArenaSplineRunHealth : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USanctuaryBossArenaHydraHealthBarComponent HealthBarComp;
	default HealthBarComp.HealthBarSegments = 6;
	default HealthBarComp.bUseHealthComp = false;
	default HealthBarComp.bEnabled = false;

	FHazeAcceleratedFloat AccHealing;
	float HealingTarget = 1.0;
	float HealingDuration = 0.2;

	UFUNCTION(BlueprintCallable)
	void SetupSplineRun()
	{
		HealthBarComp.bEnabled = true;
		HealthBarComp.SetupHealthBars();
		
		float TotalHeads = Math::FloorToFloat(CompanionAviation::HealthBarHeads);
		float HeadsToKillFloat = Math::FloorToFloat(CompanionAviation::HeadsToKill);
		float Damage = HeadsToKillFloat / TotalHeads;
		float HP = 1.0 - Damage;
		HealthBarComp.HydraBossHealthBar.Health = HP;
		AccHealing.SnapTo(HP);
		HealingTarget = HP;
	}

	UFUNCTION(BlueprintCallable)
	void SnapHealthTo(float Percent)
	{
		HealthBarComp.HydraBossHealthBar.Health = Percent;
		AccHealing.SnapTo(Percent);
		HealingTarget = Percent;
	}

	UFUNCTION(BlueprintCallable)
	void AccelerateHealthTo(float Percent, float Duration)
	{
		HealingTarget = Percent;
		HealingDuration = Duration;
	}

	UFUNCTION(BlueprintCallable)
	void ActivateHealthBarCraze()
	{
		HealthBarComp.HydraBossHealthBar.StartGrow();
	}

	UFUNCTION(BlueprintCallable)
	void ActivateHealthBarCraze2()
	{
		HealthBarComp.HydraBossHealthBar.StartGrow2();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!Math::IsNearlyEqual(AccHealing.Value, HealingTarget))
		{
			if (HealthBarComp.HydraBossHealthBar == nullptr)
				SetActorTickEnabled(false);
			AccHealing.AccelerateTo(HealingTarget, HealingDuration, DeltaSeconds);
			HealthBarComp.HydraBossHealthBar.Health = AccHealing.Value;
			if (AccHealing.Value > 1.0 - KINDA_SMALL_NUMBER)
				SetActorTickEnabled(false);
		}
	}
};