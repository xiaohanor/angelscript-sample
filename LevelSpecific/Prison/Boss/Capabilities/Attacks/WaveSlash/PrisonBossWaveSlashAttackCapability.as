class UPrisonBossWaveSlashAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	int CurrentSlashAmount = 0;
	int MaxSlashAmount = 12;
	bool bMaxSlashesReached = false;

	float CurrentTransitionTime = 0.0;
	float TransitionDuration = 0.3;

	float SlashDuration = 0.0;

	bool bFirstWaveSpawned = false;

	AHazePlayerCharacter TargetPlayer;

	bool bLeft = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CurrentTransitionTime >= TransitionDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Zoe;
		Boss.AnimationData.bIsWaveSlashing = true;

		CurrentSlashAmount = 0;
		SlashDuration = 0.0;
		bMaxSlashesReached = false;
		bFirstWaveSpawned = false;
		bLeft = true;
		CurrentTransitionTime = 0.0;

		MaxSlashAmount = Boss.bHacked ? PrisonBoss::WaveSlashPhase3Amount : PrisonBoss::WaveSlashAmount;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsWaveSlashing = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration <= PrisonBoss::WaveSlashInitialSpawnDelay)
			return;

		if (bMaxSlashesReached)
		{
			CurrentTransitionTime += DeltaTime;
			return;
		}

		if (!bFirstWaveSpawned)
		{
			bFirstWaveSpawned = true;
			SpawnWave();
		}

		SlashDuration += DeltaTime;
		if (SlashDuration >= PrisonBoss::WaveSlashInterval)
		{
			SlashDuration -= PrisonBoss::WaveSlashInterval;
			SpawnWave();
		}

		FVector TargetLoc = TargetPlayer.ActorLocation + (TargetPlayer.GetActorHorizontalVelocity() * 1.3);
		FVector DirToPlayer = (TargetLoc - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 10.0);
		Boss.SetActorRotation(Rot);
	}

	void SpawnWave()
	{
		FVector Loc = Boss.WeaponEndPointComp.WorldLocation;
		Loc.Z = Boss.ActorCenterLocation.Z;

		bLeft = !bLeft;
		FRotator Rot = Boss.WeaponEndPointComp.WorldRotation;
		Rot.Yaw = Boss.ActorRotation.Yaw;
		Rot.Pitch = 0.0;

		APrisonBossWaveSlashActor WaveSlashActor = SpawnActor(AttackDataComp.WaveSlashClass, Loc, Rot);
		WaveSlashActor.LaunchWave(Boss.ActorRotation.ForwardVector, Boss.ActorCenterLocation.Z);

		if (!TargetPlayer.OtherPlayer.IsPlayerDead())
			TargetPlayer = TargetPlayer.IsMio() ? Game::Zoe : Game::Mio;

		if (Boss.bHacked)
			TargetPlayer = Game::Zoe;

		CurrentSlashAmount++;
		if (CurrentSlashAmount >= MaxSlashAmount)
		{
			CurrentTransitionTime = SlashDuration;
			bMaxSlashesReached = true;
		}

		Boss.TriggerFeedback(EPrisonBossFeedbackType::Light, Intensity = 0.2);

		UPrisonBossEffectEventHandler::Trigger_WaveSlashAttackSpawned(Boss);
	}
}