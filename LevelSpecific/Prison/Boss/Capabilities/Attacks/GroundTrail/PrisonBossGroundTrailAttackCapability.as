class UPrisonBossGroundTrailAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FSplinePosition SplinePosition;

	FVector StartLocation;
	FVector TargetLocation;
	FRotator TargetRotation;

	int GroundTrailIndex = 0;

	TArray<APrisonBossGroundTrailAttack> TrailAttacks;

	FVector GroundLocation;

	float ExplodeStartTime = 0.0;
	bool bExplodeTimerStarted = false;
	float CurrentExplodeTime = 0.0;

	int AttacksTriggered = 0;
	float CurrentAttackDelay = 0.0;
	
	bool bTrailsActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AttacksTriggered >= PrisonBoss::MaxGroundTrails)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AttacksTriggered = 0;

		ExplodeStartTime = 0.0;
		bExplodeTimerStarted = false;
		Boss.AnimationData.bIsGroundTrailing = true;

		TrailAttacks.Empty();

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(Boss);
		Trace.IgnorePlayers();
		Trace.UseLine();

		FHitResult Hit = Trace.QueryTraceSingle(Boss.ActorLocation, Boss.ActorLocation - (FVector::UpVector * 1000.0));
		if (Hit.bBlockingHit)
			GroundLocation = Hit.ImpactPoint;

		SpawnGroundTrails();

		Boss.BP_GroundTrailSlam();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			if (Player.GetDistanceTo(Boss) <= PrisonBoss::GroundTrailSlamDamageRange)
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(FVector::UpVector, 2.0), Boss.ElectricityImpactDamageEffect, Boss.ElectricityImpactDeathEffect);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsGroundTrailing = false;

		Boss.TriggerFeedback(EPrisonBossFeedbackType::Medium, Intensity = 0.75);

		if (bTrailsActive)
			ExplodeGroundTrails();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!TrailAttacks.IsEmpty())
		{
			if (TrailAttacks[0] != nullptr)
			{
				if (TrailAttacks[0].bReachedEnd)
				{
					if (!bExplodeTimerStarted)
					{
						bExplodeTimerStarted = true;
						ExplodeStartTime = ActiveDuration;
					}
					for (APrisonBossGroundTrailAttack TrailAttack : TrailAttacks)
					{
						float Alpha = Math::GetMappedRangeValueClamped(FVector2D(ExplodeStartTime, PrisonBoss::GroundTrailExplodeDelay), FVector2D(0.0, 1.0), ActiveDuration);
						TrailAttack.UpdateExplodeAlpha(Alpha);
					}
				}
			}
		}

		if (bTrailsActive)
		{
			CurrentExplodeTime += DeltaTime;
			if (CurrentExplodeTime >= PrisonBoss::GroundTrailExplodeDelay)
			{
				ExplodeGroundTrails();
			}
		}
		else
		{
			CurrentAttackDelay += DeltaTime;
			if (CurrentAttackDelay >= PrisonBoss::GroundTrailSpawnInterval)
				SpawnGroundTrails();
		}
	}

	void SpawnGroundTrails()
	{
		float MaxCircleSplineDistance = 1350.0;
		float DrawSpeed = PrisonBoss::GroundTrailDrawSpeed;
		TArray<ASplineActor> Splines = Boss.ZigZagSplines;

		if (GroundTrailIndex == 1)
		{
			Splines = Boss.BendSplines;
			MaxCircleSplineDistance = 600.0;
		}
		if (GroundTrailIndex == 2)
			Splines = Boss.FlowerSplines;
		if (GroundTrailIndex == 3)
		{
			Splines = Boss.PentagramSplines;
			MaxCircleSplineDistance = 1100.0;
			DrawSpeed *= 1.2;
		}

		for (ASplineActor Spline : Splines)
		{
			APrisonBossGroundTrailAttack GroundTrailAttack = SpawnActor(AttackDataComp.GroundTrailClass, Boss.ActorLocation);
			TrailAttacks.Add(GroundTrailAttack);

			GroundTrailAttack.ActivateTrail(Spline.Spline, true, DrawSpeed, MaxCircleSplineDistance);
		}

		Boss.TriggerFeedback(EPrisonBossFeedbackType::Light);

		GroundTrailIndex++;
		if (GroundTrailIndex >= PrisonBoss::GroundTrailPatternAmount)
			GroundTrailIndex = 0;

		bTrailsActive = true;

		UPrisonBossEffectEventHandler::Trigger_GroundTrailSpawnTrail(Boss);
	}

	void ExplodeGroundTrails()
	{
		bTrailsActive = false;
		CurrentExplodeTime = 0.0;
		CurrentAttackDelay = 0.0;

		for (APrisonBossGroundTrailAttack TrailAttack : TrailAttacks)
		{
			TrailAttack.Explode(false);
		}

		AttacksTriggered++;

		TrailAttacks.Empty();

		UPrisonBossEffectEventHandler::Trigger_GroundTrailExplode(Boss);
	}
}