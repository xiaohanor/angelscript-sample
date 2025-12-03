class UPrisonBossHorizontalSlashEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UHazeSplineComponent SplineComp;

	FVector TargetLocation;

	bool bReachedSpline = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::HorizontalSlash)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bReachedSpline && ActiveDuration >= PrisonBoss::HorizontalSlashEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bReachedSpline = false;

		Boss.AnimationData.bIsEnteringHorizontalSlash = true;

		SplineComp = Boss.CircleSplineAirOuterUpper.Spline;

		float Fraction = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);
		TargetLocation = SplineComp.GetWorldLocationAtSplineFraction(Fraction);

		UPrisonBossEffectEventHandler::Trigger_HorizontalSlashEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringHorizontalSlash = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLocation, DeltaTime, 4000.0);
		Boss.SetActorLocation(Loc);

		FVector DirToPlayer = (Game::Zoe.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 10.0);
		Boss.SetActorRotation(Rot);

		if (Loc.Equals(TargetLocation))
			bReachedSpline = true;
	}
}