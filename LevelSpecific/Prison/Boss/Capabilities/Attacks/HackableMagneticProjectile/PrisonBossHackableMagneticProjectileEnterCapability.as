class UPrisonBossHackableMagneticProjectileEnterCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UHazeSplineComponent SplineComp;

	AHazePlayerCharacter TargetPlayer;

	bool bProjectileSpawned = false;

	FVector StartLocation;
	FVector TargetLocation;
	
	FRotator StartRotation;
	FRotator TargetRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.CurrentAttackType != EPrisonBossAttackType::HackableMagneticProjectile)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= PrisonBoss::HackableMagneticProjectileEnterDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetPlayer = Game::Mio;

		bProjectileSpawned = false;

		Boss.AnimationData.bIsEnteringHackableMagneticProjectile = true;

		// SplineComp = Boss.CircleSplineAirOuterUpper.Spline;

		/*float Fraction = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(TargetPlayer.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);
		TargetLocation = SplineComp.GetWorldLocationAtSplineFraction(Fraction);*/

		StartLocation = Boss.ActorLocation;

		ASplineActor TargetSpline = Boss.CircleSplineAirOuterUpper;
		float Fraction = Math::Wrap((TargetSpline.Spline.GetClosestSplineDistanceToWorldLocation(Game::Mio.ActorLocation)/TargetSpline.Spline.SplineLength) + 0.5, 0.0, 1.0);
		TargetLocation = TargetSpline.Spline.GetWorldLocationAtSplineFraction(Fraction);
		TargetLocation.Z += 50.0;

		StartRotation = Boss.ActorRotation;
		TargetRotation = (Boss.MiddlePoint.ActorLocation - TargetLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal().Rotation();

		UPrisonBossEffectEventHandler::Trigger_HackableMagneticProjectileEnter(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsEnteringHackableMagneticProjectile = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float EnterAlpha = Math::Clamp(ActiveDuration/PrisonBoss::HackableMagneticProjectileEnterDuration, 0.0, 1.0);
		float TranslationAlpha = AttackDataComp.GroundTrailExitCurve.GetFloatValue(ActiveDuration/PrisonBoss::HackableMagneticProjectileEnterDuration);
		float Height = Math::Lerp(StartLocation.Z, TargetLocation.Z, AttackDataComp.GroundTrailExitVerticalCurve.GetFloatValue(EnterAlpha));

		FVector Loc = Math::Lerp(StartLocation, TargetLocation, TranslationAlpha);
		FRotator Rot = Math::RInterpShortestPathTo(Boss.ActorRotation, TargetRotation, DeltaTime, 1.0);
		if (!Boss.bIsControlledByCutscene)
			Boss.SetActorLocationAndRotation(Loc, Rot);

		if (ActiveDuration >= PrisonBoss::HackableMagneticProjectileSpawnDelay)
			SpawnProjectile();
	}

	void SpawnProjectile()
	{
		if (bProjectileSpawned)
			return;

		bProjectileSpawned = true;

		Boss.SpawnHackableMagneticProjectile();

		UPrisonBossEffectEventHandler::Trigger_HackableMagneticProjectileSpawn(Boss);
	}
}