class UPrisonBossIdleCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	default CapabilityTags.Add(n"Idle");

	UHazeSplineComponent SplineComp;

	float Fraction = 0.0;

	FVector DeltaMove;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsIdling = true;

		SplineComp = Boss.CircleSplineAirInner.Spline;

		Fraction = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsIdling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SplineComp = Boss.CircleSplineAirInner.Spline;
		
		// AHazePlayerCharacter ClosestPlayer = Boss.GetDistanceTo(Game::Mio) > Boss.GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;
		AHazePlayerCharacter ClosestPlayer = Boss.IdleTargetPlayer;
		if (Boss.bHacked)
			ClosestPlayer = Game::Zoe;

		FVector DirToPlayer = (ClosestPlayer.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 3.0);
		Boss.SetActorRotation(Rot);

		float Frac = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);
		Fraction = Math::FInterpTo(Fraction, Frac, DeltaTime, 0.25);

		FVector Loc = Math::VInterpTo(Boss.ActorLocation, SplineComp.GetWorldLocationAtSplineFraction(Frac), DeltaTime, 0.75);

		FVector MoveDir = (Loc - Boss.ActorLocation).GetSafeNormal();

		Boss.SetActorLocation(Loc);

		// FVector LocalDir = Boss.ActorTransform.TransformVector(MoveDir);
		
		// Boss.AnimationData.IdleBlendSpaceValue = FVector2D(-LocalDir.X, 0.0);
	}
}