class UPrisonBossSpiralEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	bool bReachedSpline = false;

	ASplineActor SpiralSpline;

	FVector StartLocation;
	FVector TargetLocation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::Spiral)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::SpiralEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = Boss.ActorLocation;

		bReachedSpline = false;
		SpiralSpline = Boss.SpiralSpline;

		FVector DirToSpiral = (Boss.ActorLocation- Boss.MiddlePoint.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		FRotator SpiralRot = DirToSpiral.Rotation();
		SpiralRot.Yaw -= 90.0;
		SpiralSpline.SetActorRotation(SpiralRot);

		Boss.AnimationData.bIsEnteringSpiral = true;

		TargetLocation = SpiralSpline.Spline.GetWorldLocationAtSplineFraction(1.0);
		TargetRotation = SpiralSpline.Spline.GetWorldRotationAtSplineFraction(1.0).Rotator();
		TargetRotation.Yaw += 180.0;

		UPrisonBossEffectEventHandler::Trigger_SpiralEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.SetActorLocationAndRotation(TargetLocation, TargetRotation);
		Boss.AnimationData.bIsEnteringSpiral = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Clamp(AttackDataComp.SpiralEnterCurve.GetFloatValue(ActiveDuration/PrisonBoss::SpiralEnterDuration), 0.0, 1.0);

		FVector Loc = Math::Lerp(StartLocation, TargetLocation, Alpha);
		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, TargetRotation, DeltaTime, 2.0);
		Boss.SetActorRotation(Rot);
	}
}