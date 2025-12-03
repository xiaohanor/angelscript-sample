class UPrisonBossZigZagAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	int CurrentAttackAmount = 0;
	bool bMaxAttacksReached = false;

	float AttackDuration = 0.0;
	bool bAttackSpawned = false;

	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bMaxAttacksReached)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Zoe;
		Boss.AnimationData.bZigZagAttacking = true;

		AttackDuration = 0.0;
		CurrentAttackAmount = 0;
		bMaxAttacksReached = false;
		bAttackSpawned = false;

		Boss.TriggerInactiveDangerZones();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bZigZagAttacking = false;

		// Remote side may miss a wave if the deactivation crumb comes in too early
		if (CurrentAttackAmount < PrisonBoss::ZigZagAmount)
			SpawnWave();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AttackDuration += DeltaTime;
		if (!bAttackSpawned && AttackDuration >= PrisonBoss::ZigZagSpawnDelay)
		{
			bAttackSpawned = true;
			SpawnWave();
		}
		if (AttackDuration >= PrisonBoss::ZigZagInterval)
		{
			bAttackSpawned = false;
			AttackDuration -= PrisonBoss::ZigZagInterval;
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

		FRotator Rot = Boss.WeaponEndPointComp.WorldRotation;
		Rot.Yaw = Boss.ActorRotation.Yaw;
		Rot.Pitch = 0.0;
		Rot.Roll = 0.0;

		FVector DirToPlayer = (TargetPlayer.ActorLocation - Boss.ZigZagSpline.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		float RotOffset = Math::RandRange(-10.0, 10.0);
		Boss.ZigZagSpline.SetActorRotation(DirToPlayer.Rotation() + FRotator(0.0, RotOffset, 0.0));
		APrisonBossZigZagAttack ZigZagActor = SpawnActor(AttackDataComp.ZigZagClass, Loc, Rot);
		ZigZagActor.LaunchAttack(Boss.ZigZagSpline);

		CurrentAttackAmount++;
		if (CurrentAttackAmount >= PrisonBoss::ZigZagAmount)
			bMaxAttacksReached = true;

		Boss.TriggerFeedback(EPrisonBossFeedbackType::Light, Intensity = 0.2);

		UPrisonBossEffectEventHandler::Trigger_ZigZagSpawnAttack(Boss);
	}
}