struct FPrisonBossCloneEnterActivationParams
{
	FVector TargetLocation;
}

class UPrisonBossCloneEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UPrisonBossCloneManagerComponent CloneComp;

	ASplineActor TargetSpline;

	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		CloneComp = UPrisonBossCloneManagerComponent::GetOrCreate(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonBossCloneEnterActivationParams& Params) const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::Clone)
			return false;

		Params.TargetLocation = Boss.CircleSplineAirOuterLower.Spline.GetClosestSplineWorldLocationToWorldLocation(Boss.ActorLocation);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::CloneEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonBossCloneEnterActivationParams Params)
	{
		Boss.AnimationData.bIsEnteringClone = true;

		TargetSpline = Boss.CircleSplineAirOuterLower;

		// float Fraction = Math::Wrap((TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation)/TargetSpline.Spline.SplineLength) + 0.5, 0.0, 1.0);
		// TargetLocation = TargetSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
		TargetLocation = Params.TargetLocation;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.ApplyCameraSettings(AttackDataComp.CloneCamSettings, 4.0, CloneComp, EHazeCameraPriority::VeryHigh);
		
		UPrisonBossEffectEventHandler::Trigger_CloneEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringClone = false;
		Boss.SetActorLocation(TargetLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Loc = Math::VInterpTo(Boss.ActorLocation, TargetLocation, DeltaTime, 3.0);
		Boss.SetActorLocation(Loc);

		FVector DirToMid = (Boss.MiddlePoint.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToMid.Rotation(), DeltaTime, 8.0);
		Boss.SetActorRotation(Rot);
	}
}