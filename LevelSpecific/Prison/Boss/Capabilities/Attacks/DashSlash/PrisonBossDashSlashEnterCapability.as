class UPrisonBossDashSlashEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UHazeSplineComponent SplineComp;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::DashSlash)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::DashSlashEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsEnteringDashSlash = true;

		SplineComp = Boss.CircleSplineAirOuterLower.Spline;

		// float Fraction = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);
		// TargetLocation = SplineComp.GetWorldLocationAtSplineFraction(Fraction);
		TargetLocation = SplineComp.GetClosestSplineWorldLocationToWorldLocation(Boss.ActorLocation);
		TargetLocation.Z += 80.0;

		UPrisonBossEffectEventHandler::Trigger_DashSlashEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringDashSlash = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLocation, DeltaTime, 3.0);
		Boss.SetActorLocation(Loc);

		FVector DirToPlayer = (Game::Zoe.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 10.0);
		Boss.SetActorRotation(Rot);
	}
}