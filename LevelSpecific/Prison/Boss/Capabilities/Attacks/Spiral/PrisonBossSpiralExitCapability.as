class UPrisonBossSpiralExitCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector StartLocation;
	FVector TargetLocation;
	
	FRotator StartRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::SpiralExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.AnimationData.bIsExitingSpiral = true;

		StartLocation = Boss.ActorLocation;

		ASplineActor TargetSpline = Boss.CircleSplineAirOuterLower;
		float Fraction = Math::Wrap((TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/TargetSpline.Spline.SplineLength) + 0.5, 0.0, 1.0);
		TargetLocation = TargetSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
		TargetLocation.Z += 100.0;

		StartRotation = Boss.ActorRotation;
		TargetRotation = (Boss.MiddlePoint.ActorLocation - TargetLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();

		UPrisonBossEffectEventHandler::Trigger_SpiralExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsExitingSpiral = false;
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::Spiral);

		UPrisonBossEffectEventHandler::Trigger_SpiralFinished(Boss);

		Boss.SetActorLocationAndRotation(TargetLocation, TargetRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ExitAlpha = Math::Clamp(ActiveDuration/PrisonBoss::SpiralExitDuration, 0.0, 1.0);
		float TranslationAlpha = AttackDataComp.GroundTrailExitCurve.GetFloatValue(ActiveDuration/PrisonBoss::SpiralExitDuration);
		float Height = Math::Lerp(StartLocation.Z, TargetLocation.Z, AttackDataComp.GroundTrailExitVerticalCurve.GetFloatValue(ExitAlpha));

		FVector Loc = Math::Lerp(StartLocation, TargetLocation, TranslationAlpha);
		Loc.Z = Height;

		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, TargetRotation, DeltaTime, 1.0);
		Boss.SetActorRotation(Rot);
	}
}