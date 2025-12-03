class UPrisonBossChaseMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Chase");

	APrisonBoss Boss;

	UHazeSplineComponent SplineComp;

	float CurrentSplineDist = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<APrisonBoss>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.bChasing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boss.bChasing)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsIdling = true;

		SplineComp = Boss.ChaseSpline.Spline;

		Boss.BlockCapabilities(n"PrisonBossCompound", this);

		AHazePlayerCharacter ClosestPlayer = Boss.GetDistanceTo(Game::Mio) > Boss.GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;
		CurrentSplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(ClosestPlayer.ActorLocation) + Boss.ChaseSplineOffset;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsIdling = false;

		Boss.UnblockCapabilities(n"PrisonBossCompound", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter ClosestPlayer = Boss.GetDistanceTo(Game::Mio) > Boss.GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;

		if (Boss.CurrentAttackType != EPrisonBossAttackType::GrabDebris)
		{
			FVector DirToPlayer = (ClosestPlayer.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 3.0);
			Boss.SetActorRotation(Rot);
		}

		float TargetSplineDist = SplineComp.GetClosestSplineDistanceToWorldLocation(ClosestPlayer.ActorLocation) + Boss.ChaseSplineOffset;
		CurrentSplineDist = Math::FInterpTo(CurrentSplineDist, TargetSplineDist, DeltaTime, 0.5);

		if (Boss.StaticChasePoint != nullptr)
		{
			FVector Loc = Math::VInterpTo(Boss.ActorLocation, Boss.StaticChasePoint.ActorLocation, DeltaTime, Boss.StaticChasePointInterpSpeed);
			Boss.SetActorLocation(Loc);
		}

		else if (!Boss.bChasePaused)
		{
			FVector Loc = Math::VInterpTo(Boss.ActorLocation, SplineComp.GetWorldLocationAtSplineDistance(CurrentSplineDist), DeltaTime, 2.0);
			Boss.SetActorLocation(Loc);
		}
	}
}