struct FPrisonBossGroundTrailExitActivationParams
{
	FVector TargetLocation;
}

class UPrisonBossGroundTrailExitCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector StartLocation;
	FVector TargetLocation;
	
	FRotator StartRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonBossGroundTrailExitActivationParams& Params) const
	{
		ASplineActor TargetSpline = Boss.CircleSplineAirOuterLower;
		float Fraction = Math::Wrap((TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/TargetSpline.Spline.SplineLength) + 0.5, 0.0, 1.0);
		Params.TargetLocation = TargetSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
		Params.TargetLocation.Z += 100.0;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::GroundTrailExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonBossGroundTrailExitActivationParams Params)
	{
		Boss.AnimationData.bIsExitingGroundTrail = true;

		StartLocation = Boss.ActorLocation;
		TargetLocation = Params.TargetLocation;

		StartRotation = Boss.ActorRotation;
		TargetRotation = (Boss.MiddlePoint.ActorLocation - TargetLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();

		UPrisonBossEffectEventHandler::Trigger_GroundTrailExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsExitingGroundTrail = false;
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::GroundTrail);
		Boss.SetActorLocationAndRotation(TargetLocation, TargetRotation);

		UPrisonBossEffectEventHandler::Trigger_GroundTrailFinished(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ExitAlpha = Math::Clamp(ActiveDuration/PrisonBoss::GroundTrailExitDuration, 0.0, 1.0);
		float TranslationAlpha = AttackDataComp.GroundTrailExitCurve.GetFloatValue(ActiveDuration/PrisonBoss::GroundTrailExitDuration);
		float Height = Math::Lerp(StartLocation.Z, TargetLocation.Z, AttackDataComp.GroundTrailExitVerticalCurve.GetFloatValue(ExitAlpha));

		FVector Loc = Math::Lerp(StartLocation, TargetLocation, TranslationAlpha);
		Loc.Z = Height;

		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, TargetRotation, DeltaTime, 1.0);
		Boss.SetActorRotation(Rot);
	}
}