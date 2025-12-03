class UPrisonBossDashSlashAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazePlayerCharacter TargetPlayer;

	FVector TargetLocation;

	int CurrentAttackAmount = 0;

	bool bTelegraphing = false;
	float CurrentTelegraphDuration = 0.0;

	bool bAttacking = false;
	float CurrentAttackStartTime = 0.0;
	
	bool bReachedEnd = false;
	float CurrentWindDownDuration = 0.0;

	bool bMaxAttacksReached = false;

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
		CurrentAttackAmount = 0;

		bTelegraphing = false;
		CurrentTelegraphDuration = 0.0;

		bAttacking = false;
		bReachedEnd = false;
		CurrentAttackStartTime = 0.0;

		bMaxAttacksReached = false;

		Boss.AnimationData.bDashSlashReachedEnd = false;
		Boss.AnimationData.bIsDashSlashAttacking = false;
		Boss.AnimationData.bIsDashSlashTelegraphing = true;

		TargetPlayer = Game::Zoe;
		StartTelegraphing();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsDashSlashTelegraphing = false;
		Boss.AnimationData.bIsDashSlashAttacking = false;
		Boss.AnimationData.bDashSlashReachedEnd = false;

		if (!bReachedEnd && bAttacking)
		{
			UPrisonBossEffectEventHandler::Trigger_DashSlashAttackReachedEnd(Boss);
			bReachedEnd = true;
			bAttacking = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bTelegraphing)
		{
			FVector DirToPlayer = (TargetPlayer.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			CurrentTelegraphDuration += DeltaTime;
			if (CurrentTelegraphDuration >= PrisonBoss::DashSlashTelegraphDuration)
			{
				Attack();
			}

			if (CurrentTelegraphDuration <= PrisonBoss::DashSlashAlignDuration)
			{
				FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 10.0);
				Boss.SetActorRotation(Rot);
			}
		}
		else if (bAttacking)
		{
			if (CurrentAttackStartTime < PrisonBoss::DashSlashAttackWindUpDuration)
			{
				CurrentAttackStartTime += DeltaTime;
				return;
			}

			FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLocation, DeltaTime, PrisonBoss::DashSlashSpeed);
			Boss.SetActorLocation(Loc);

			bool bPreviousReachedEnd = bReachedEnd;
			if (Boss.ActorLocation.Distance(TargetLocation) <= 10.0)
			{
				bReachedEnd = true;
			}
			else if (Boss.ActorLocation.Distance(TargetLocation) <= 1200.0)
			{
				Boss.AnimationData.bIsDashSlashAttacking = false;
				Boss.AnimationData.bDashSlashReachedEnd = true;
			}

			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				if (Boss.ActorLocation.IsWithinDist(Player.ActorLocation, PrisonBoss::DashSlashDamageRange))
					Player.DamagePlayerHealth(1.0, FPlayerDeathDamageParams(Boss.ActorForwardVector, 2.0), Boss.ElectricityImpactDamageEffect, Boss.ElectricityImpactDeathEffect);
			}

			if (bReachedEnd)
			{
				CurrentWindDownDuration += DeltaTime;

				FRotator TargetRot = (Boss.MiddlePoint.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();
				FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, TargetRot, DeltaTime, 2.0);
				Boss.SetActorRotation(Rot);

				if (!bPreviousReachedEnd)
					UPrisonBossEffectEventHandler::Trigger_DashSlashAttackReachedEnd(Boss);

				if (CurrentWindDownDuration >= PrisonBoss::DashSlashAttackWindDownDuration)
				{
					if (CurrentAttackAmount >= PrisonBoss::DashSlashAttackAmount)
					{
						Boss.AnimationData.bDashSlashReachedEnd = false;
						Boss.AnimationData.bIsDashSlashAttacking = false;
						bMaxAttacksReached = true;
						return;
					}

					
					Boss.AnimationData.bDashSlashReachedEnd = false;
					Boss.AnimationData.bIsDashSlashAttacking = false;

					StartTelegraphing();
					bAttacking = false;
				}
			}
		}
	}

	void StartTelegraphing()
	{
		if (!Boss.bHacked)
		{
			if (!TargetPlayer.OtherPlayer.IsPlayerDead())
				TargetPlayer = TargetPlayer.IsMio() ? Game::Zoe : Game::Mio;
		}

		CurrentTelegraphDuration = 0.0;

		bReachedEnd = false;
		bTelegraphing = true;
		CurrentAttackStartTime = 0.0;
		CurrentWindDownDuration = 0.0;

		Boss.AnimationData.bIsDashSlashTelegraphing = true;

		UPrisonBossEffectEventHandler::Trigger_DashSlashTelegraph(Boss);
	}

	void Attack()
	{
		Boss.AnimationData.bIsDashSlashTelegraphing = false;
		Boss.AnimationData.bIsDashSlashAttacking = true;

		bTelegraphing = false;
		CurrentTelegraphDuration = 0.0;

		FLineSphereIntersection Intersection = Math::GetInfiniteLineSphereIntersectionPoints(Boss.ActorLocation, Boss.ActorForwardVector, Boss.MiddlePoint.ActorLocation, 2000.0);
		TargetLocation = Intersection.MaxIntersection;

		bAttacking = true;

		CurrentAttackAmount++;

		UPrisonBossEffectEventHandler::Trigger_DashSlashAttackStarted(Boss);
	}
}