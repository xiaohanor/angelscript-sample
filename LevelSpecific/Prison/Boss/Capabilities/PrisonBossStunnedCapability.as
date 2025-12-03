struct FPrisonBossStunnedActivationParams
{
	bool bStunnedAirborne = false;
}

class UPrisonBossStunnedCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector TargetLoc;
	float StunDuration = 8.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonBossStunnedActivationParams& Params) const
	{
		if (!Boss.bStunned)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if (ActiveDuration >= StunDuration)
			// return true;

		if (!Boss.bStunned)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonBossStunnedActivationParams Params)
	{
		if (Params.bStunnedAirborne)
		{
			Boss.AnimationData.bIsAirborneStunned = true;
			StunDuration = 16.0;
		}

		Boss.AnimationData.bIsStunned = true;

		ASplineActor TargetSpline = Params.bStunnedAirborne ? Boss.CircleSplineAirInner : Boss.CircleSplineGroundInner;

		if (Boss.bHacked)
		{
			TargetLoc = Boss.MiddlePoint.ActorLocation;
			TargetLoc.Z += 400.0;
		}
		else if (Params.bStunnedAirborne)
		{
			// float Fraction = Math::Wrap((TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Zoe.ActorLocation)/TargetSpline.Spline.SplineLength) + 0.5, 0.0, 1.0);
			// TargetLoc = TargetSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
			TargetLoc = Boss.MiddlePoint.ActorLocation;
		}
		else
		{
			TargetLoc = TargetSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Boss.ActorLocation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsAirborneStunned = false;
		Boss.AnimationData.bIsStunned = false;

		Boss.OnRecoveredFromStun.Broadcast(Boss.bStunned);

		Boss.bStunned = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLoc, DeltaTime, 1.0);
		Boss.SetActorLocation(Loc);

		FVector DirToMid = (Boss.MiddlePoint.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToMid.Rotation(), DeltaTime, 12.0);
		// Boss.SetActorRotation(Rot);
	}
}