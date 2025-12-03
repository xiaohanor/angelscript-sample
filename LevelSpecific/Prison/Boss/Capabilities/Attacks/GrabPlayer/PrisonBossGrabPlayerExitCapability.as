class UPrisonBossGrabPlayerExitCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	FVector StartLocation;
	FVector TargetLocation;
	
	FRotator StartRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::ChokeExitDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = Boss.ActorLocation;

		FVector DirFromZoe = (Boss.Mesh.GetSocketLocation(n"Hips") - Game::Zoe.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		FLineSphereIntersection Intersection = Math::GetInfiniteLineSphereIntersectionPoints(Boss.ActorLocation, DirFromZoe, Boss.MiddlePoint.ActorLocation, 2000.0);
		TargetLocation = Intersection.MaxIntersection;
		TargetLocation = Boss.CircleSplineAirOuterLower.Spline.GetClosestSplineWorldLocationToWorldLocation(TargetLocation);
		TargetLocation.Z += 100.0;

		StartRotation = Boss.ActorRotation;
		TargetRotation = (Boss.MiddlePoint.ActorLocation - TargetLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();
		UPrisonBossEffectEventHandler::Trigger_GrabPlayerExit(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.CurrentAttackType = EPrisonBossAttackType::None;

		Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::GrabPlayer);

		float Height = Math::Lerp(StartLocation.Z, TargetLocation.Z, AttackDataComp.GroundTrailExitVerticalCurve.GetFloatValue(1.0));
		FVector Loc = TargetLocation;
		Loc.Z = Height;

		Boss.SetActorLocation(Loc);
		Boss.SetActorRotation(TargetRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ExitAlpha = Math::Clamp(ActiveDuration/PrisonBoss::ChokeExitDuration, 0.0, 1.0);
		float TranslationAlpha = AttackDataComp.GroundTrailExitCurve.GetFloatValue(ActiveDuration/PrisonBoss::ChokeExitDuration);
		float Height = Math::Lerp(StartLocation.Z, TargetLocation.Z, AttackDataComp.GroundTrailExitVerticalCurve.GetFloatValue(ExitAlpha));

		FVector Loc = Math::Lerp(StartLocation, TargetLocation, TranslationAlpha);
		Loc.Z = Height;

		Boss.SetActorLocation(Loc);

		FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, TargetRotation, DeltaTime, 1.0);
		Boss.SetActorRotation(Rot);
	}
}