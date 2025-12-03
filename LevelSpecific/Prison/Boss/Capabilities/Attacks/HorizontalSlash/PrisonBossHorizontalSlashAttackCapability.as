class UPrisonBossHorizontalSlashAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazePlayerCharacter TargetPlayer;
	float CurrentExitDuration = 0.0;

	bool bProjectileSpawned = false;

	int CurrentSlashAmount = 0;

	float CurrentSlashDelay = 0.0;

	float Fraction;

	UHazeSplineComponent SplineComp;

	bool bExiting = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CurrentExitDuration >= PrisonBoss::HorizontalSlashExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bProjectileSpawned = false;
		TargetPlayer = Game::Zoe;

		CurrentSlashAmount = 0;
		CurrentSlashDelay = 0.0;
		CurrentExitDuration = 0.0;
		
		SplineComp = Boss.CircleSplineAirInner.Spline;

		Fraction = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);

		// Boss.TriggerInactiveDangerZones();
		Boss.AnimationData.bIsHorizontalSlashing = true;

		TriggerAttack();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.SetTargetIdleTime(1.0);

		Boss.CurrentAttackType = EPrisonBossAttackType::None;
		Boss.AnimationData.bIsHorizontalSlashing = false;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::HorizontalSlash);

		UPrisonBossEffectEventHandler::Trigger_HorizontalSlashExit(Boss);
		UPrisonBossEffectEventHandler::Trigger_HorizontalSlashFinished(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DirToPlayer = (Game::Zoe.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 10.0);
		Boss.SetActorRotation(Rot);

		CurrentSlashDelay += DeltaTime;
		if (CurrentSlashDelay >= PrisonBoss::HorizontalSlashInterval && CurrentSlashAmount < PrisonBoss::HorizontalSlashAmount)
			TriggerAttack();

		SplineComp = Boss.CircleSplineAirInner.Spline;
		
		AHazePlayerCharacter ClosestPlayer = Boss.GetDistanceTo(Game::Mio) > Boss.GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;
		if (Boss.bHacked)
			ClosestPlayer = Game::Zoe;

		float Frac = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);
		Fraction = Math::FInterpTo(Fraction, Frac, DeltaTime, 0.25);

		FVector Loc = Math::VInterpTo(Boss.ActorLocation, SplineComp.GetWorldLocationAtSplineFraction(Frac), DeltaTime, 0.75);

		FVector MoveDir = (Loc - Boss.ActorLocation).GetSafeNormal();

		Boss.SetActorLocation(Loc);

		if (CurrentSlashAmount > PrisonBoss::HorizontalSlashAmount - 1 && ActiveDuration >= PrisonBoss::HorizontalSlashAmount)
		{
			Boss.AnimationData.bIsHorizontalSlashing = false;
			CurrentExitDuration += DeltaTime;
		}
	}

	void TriggerAttack()
	{
		CurrentSlashDelay = 0.0;
		Timer::SetTimer(this, n"SpawnProjectile", PrisonBoss::HorizontalSlashSpawnDelay);
	}

	UFUNCTION()
	void SpawnProjectile()
	{
		CurrentSlashAmount++;
		APrisonBossHorizontalSlashActor AttackActor = SpawnActor(AttackDataComp.HorizontalSlashClass, Boss.ActorLocation, Boss.ActorRotation);

		Boss.TriggerFeedback(EPrisonBossFeedbackType::Light, 0.5, Player = EHazeSelectPlayer::Zoe);

		UPrisonBossEffectEventHandler::Trigger_HorizontalSlashAttackSpawned(Boss);
	}
}