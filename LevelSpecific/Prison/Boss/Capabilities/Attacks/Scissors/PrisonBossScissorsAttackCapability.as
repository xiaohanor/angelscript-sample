class UPrisonBossScissorsAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazePlayerCharacter TargetPlayer;

	APrisonBossScissorsAttack LeftScissors;
	APrisonBossScissorsAttack RightScissors;

	bool bSweeping = false;
	float CurrentSweepDuration = 0.0;

	float CurrentPauseDuration = 0.0;

	int CurrentSweepAmount = 0;

	bool bScissorsSpawned = false;

	bool bFinalSweep = false;
	float FinalSweepDuration = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (FinalSweepDuration >= PrisonBoss::ScissorsSweepDuration + PrisonBoss::ScissorsSweepInterval)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Zoe;

		bScissorsSpawned = false;
		bSweeping = true;
		CurrentSweepDuration = 0.0;
		CurrentPauseDuration = 0.0;
		CurrentSweepAmount = 0;
		bFinalSweep = false;
		FinalSweepDuration = 0.0;

		Boss.AnimationData.bIsScissorsAttacking = true;

		SpawnScissors();
	}

	void SpawnScissors()
	{
		bScissorsSpawned = true;

		LeftScissors = SpawnActor(AttackDataComp.ScissorsClass, Boss.ActorLocation + (FVector::UpVector * 75.0), Boss.ActorRotation);
		LeftScissors.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld);
		LeftScissors.SetRotation(-45.0);	

		RightScissors = SpawnActor(AttackDataComp.ScissorsClass, Boss.ActorLocation + (FVector::UpVector * 75.0), Boss.ActorRotation);
		RightScissors.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld);
		RightScissors.SetRotation(45.0);

		UPrisonBossEffectEventHandler::Trigger_ScissorsAttackSpawned(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsScissorsAttacking = false;

		LeftScissors.Despawn();
		RightScissors.Despawn();

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::Scissors);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration <= PrisonBoss::ScissorsSweepInitialDelay)
			return;

		if (bFinalSweep)
		{
			FinalSweepDuration += DeltaTime;
		}

		if (bSweeping)
		{
			CurrentSweepDuration += DeltaTime;
			float SweepNormalizedAlpha = CurrentSweepDuration/PrisonBoss::ScissorsSweepDuration;
			float SweepAlpha = AttackDataComp.ScissorsSweepCurve.GetFloatValue(SweepNormalizedAlpha);

			float ScissorsRot = Math::Lerp(PrisonBoss::ScissorsSweepAngle, -PrisonBoss::ScissorsSweepAngle, SweepAlpha);
			LeftScissors.SetRotation(ScissorsRot);
			RightScissors.SetRotation(-ScissorsRot);
			LeftScissors.SweepAlpha = SweepAlpha;

			if (bFinalSweep)
				return;

			if (SweepNormalizedAlpha >= 1.0)
				SweepFinished();
		}
		else
		{
			CurrentPauseDuration += DeltaTime;
			if (CurrentPauseDuration >= PrisonBoss::ScissorsSweepInterval)
				TriggerSweep();
		}

		AActor TargetActor = Boss.Platforms[0];
		for (AActor Actor : Boss.Platforms)
		{
			float Dist = Game::Zoe.GetDistanceTo(Actor);
			if (TargetActor.GetDistanceTo(Game::Zoe) > Dist)
				TargetActor = Actor;
		}

		FRotator TargetRotation = (TargetActor.ActorLocation - Boss.MiddlePoint.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, TargetRotation, DeltaTime, 3.0);
		Boss.SetActorRotation(Rot);
	}

	void TriggerSweep()
	{
		CurrentSweepDuration = 0.0;
		bSweeping = true;

		if (CurrentSweepAmount >= PrisonBoss::ScissorsSweepAmount - 1)
			bFinalSweep = true;
	}

	void SweepFinished()
	{
		CurrentSweepAmount++;

		CurrentPauseDuration = 0.0;
		bSweeping = false;
	}
}