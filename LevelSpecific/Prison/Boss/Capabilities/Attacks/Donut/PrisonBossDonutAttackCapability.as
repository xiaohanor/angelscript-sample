class UPrisonBossDonutAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"Donut");

	default TickGroup = EHazeTickGroup::Gameplay;

	APrisonBoss Boss;

	bool bSpawningDonut = false;

	float TimeUntilNextDonut = 0.0;

	APrisonBossDonutAttack CurrentDonut;
	float CurrentSpawnDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::Donut)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!bSpawningDonut && Boss.CurrentAttackType != EPrisonBossAttackType::Donut)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentSpawnDuration = 0.0;
		bSpawningDonut = false;

		TimeUntilNextDonut = PrisonBoss::DonutSpawnInterval;

		UPrisonBossEffectEventHandler::Trigger_DonutEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPrisonBossEffectEventHandler::Trigger_DonutExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bSpawningDonut)
		{
			CurrentSpawnDuration += DeltaTime;
			float SpawnAlpha = Math::Saturate(CurrentSpawnDuration/PrisonBoss::DonutSpawnDuration);
			CurrentDonut.UpdateSpawnFraction(SpawnAlpha);

			if (SpawnAlpha >= 1.0)
				DonutFullySpawned();
		}

		TimeUntilNextDonut += DeltaTime;
		if (TimeUntilNextDonut >= PrisonBoss::DonutSpawnInterval)
			SpawnDonut();
	}

	void SpawnDonut()
	{
		TimeUntilNextDonut = 0.0;

		Boss.AnimationData.bSpawningDonut = true;
		Timer::SetTimer(this, n"ResetDonutBool", 2.4);

		Timer::SetTimer(this, n"ActuallySpawnDonut", PrisonBoss::DonutSpawnDelay);

		UPrisonBossEffectEventHandler::Trigger_DonutSpawnAttack(Boss);
	}

	UFUNCTION()
	private void ActuallySpawnDonut()
	{
		if (!IsActive())
			return;

		CurrentSpawnDuration = 0.0;

		CurrentDonut = SpawnActor(Boss.AttackDataComp.DonutClass, Boss.ActorLocation, Boss.ActorRotation);
		CurrentDonut.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld);

		bSpawningDonut = true;
	}

	UFUNCTION()
	private void ResetDonutBool()
	{
		Boss.AnimationData.bSpawningDonut = false;
	}

	void DonutFullySpawned()
	{
		bSpawningDonut = false;
		CurrentDonut.FullySpawned();
	}
}