class UPrisonBossHackableMagneticProjectileThrowCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AHazePlayerCharacter TargetPlayer;

	bool bProjectileLaunched = false;
	bool bProjectileHacked = false;

	UHazeSplineComponent SplineComp;
	float SplineFraction = 0.0;

	bool bVolleyActivated = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boss.bHackableMagneticProjectileActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Boss.bHackableMagneticProjectileActive = true;
		Boss.bMagneticProjectileHacked = false;

		bVolleyActivated = false;
		bProjectileLaunched = false;
		bProjectileHacked = false;
		TargetPlayer = Game::Mio;

		SplineComp = Boss.CircleSplineAirOuterUpper.Spline;

		Boss.AnimationData.bIsLaunchingHackableMagneticProjectile = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Boss.AnimationData.bHackableMagneticProjectileHitReaction)
		{

		}
		else
		{
			Boss.OnAttackCompleted.Broadcast(EPrisonBossAttackType::HackableMagneticProjectile);
			UPrisonBossEffectEventHandler::Trigger_HackableMagneticProjectileExit(Boss);
			Boss.CurrentAttackType = EPrisonBossAttackType::None;
		}

		Boss.AnimationData.bIsLaunchingHackableMagneticProjectile = false;
		Boss.AnimationData.bIsSpawningHackableMagneticProjectile = false;

		Boss.DeactivateVolley();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bVolleyActivated && ActiveDuration >= PrisonBoss::HackableMagneticProjectileVolleyDelay)
		{
			FPrisonBossVolleyData VolleyData;
			VolleyData.ProjectilesPerVolley = 4;
			Boss.ActivateVolley(VolleyData);
		}

		if (ActiveDuration >= PrisonBoss::HackableMagneticProjectileLaunchDelay)
		{
			LaunchProjectile();
		}

		if (bProjectileHacked)
		{
			FVector DirToPlayer = (TargetPlayer.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 3.0);
			Boss.SetActorRotation(Rot);

			float Frac = Math::Wrap((SplineComp.GetClosestSplineDistanceToWorldLocation(TargetPlayer.ActorLocation)/SplineComp.SplineLength) + 0.5, 0.0, 1.0);
			SplineFraction = Math::FInterpTo(SplineFraction, Frac, DeltaTime, 0.25);

			FVector Loc = Math::VInterpTo(Boss.ActorLocation, SplineComp.GetWorldLocationAtSplineFraction(Frac), DeltaTime, 0.75);
			FVector MoveDir = (Loc - Boss.ActorLocation).GetSafeNormal();

			if (!Boss.bIsControlledByCutscene)
				Boss.SetActorLocation(Loc);
		}
		else
		{
			FVector DirToPlayer = (Game::Zoe.ActorLocation - Boss.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			FRotator Rot = Math::RInterpTo(Boss.ActorRotation, DirToPlayer.Rotation(), DeltaTime, 10.0);

			if (!Boss.bIsControlledByCutscene)
				Boss.SetActorRotation(Rot);
		}

		if (!bProjectileHacked && Boss.bMagneticProjectileHacked)
		{
			ProjectileHacked();
		}
	}

	void LaunchProjectile()
	{
		if (bProjectileLaunched)
			return;

		bProjectileLaunched = true;
		Boss.CurrentHackableMagneticProjectile.Launch();

		UPrisonBossEffectEventHandler::Trigger_HackableMagneticProjectileLaunch(Boss);
	}

	void ProjectileHacked()
	{
		TargetPlayer = Game::Zoe;
		SplineFraction = SplineComp.GetClosestSplineDistanceToWorldLocation(TargetPlayer.ActorLocation/SplineComp.SplineLength);
		bProjectileHacked = true;
	}
}