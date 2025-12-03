struct FPrisonBossWaveSlashActivationParams
{
	bool bIsHacked = false;
	FVector ClosestSplinePos;
}

class UPrisonBossWaveSlashEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	ASplineActor TargetSpline;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonBossWaveSlashActivationParams& Params) const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::WaveSlash)
			return false;

		Params.bIsHacked = Boss.IsHacked();
		Params.ClosestSplinePos = Boss.CircleSplineAirOuterLower.Spline.GetClosestSplineWorldLocationToWorldLocation(Boss.ActorLocation);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::WaveSlashEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonBossWaveSlashActivationParams Params)
	{
		Boss.AnimationData.bIsEnteringWaveSlash = true;

		if (Params.bIsHacked)
		{
			TargetLocation = Boss.MiddlePoint.ActorLocation + (FVector::UpVector * 120.0);
		}
		else
		{
			TargetSpline = Boss.CircleSplineAirOuterLower;

			// float Fraction = Math::Wrap((TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/TargetSpline.Spline.SplineLength) + 0.5, 0.0, 1.0);
			// TargetLocation = TargetSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
			TargetLocation = Params.ClosestSplinePos;
			TargetLocation.Z += 100.0;
		}

		UPrisonBossEffectEventHandler::Trigger_WaveSlashEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringWaveSlash = false;
		Boss.SetActorLocation(TargetLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLocation, DeltaTime, 2.0);
		Boss.SetActorLocation(Loc);

		FVector Dir = (Game::Zoe.ActorLocation - Boss.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, Dir.Rotation(), DeltaTime, 10.0);
		Boss.SetActorRotation(Rot);
	}
}