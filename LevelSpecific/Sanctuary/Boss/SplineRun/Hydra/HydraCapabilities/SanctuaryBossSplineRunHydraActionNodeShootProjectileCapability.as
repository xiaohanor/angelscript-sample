struct FSanctuaryBossSplineRunHydraActionNodeShootProjectileData
{
	ASanctuaryBossSplineRunHydraProjectileTarget ProjectileTarget;
}

class USanctuaryBossSplineRunHydraActionNodeShootProjectileCapability : UHazeCapability
{
	FSanctuaryBossSplineRunHydraActionNodeShootProjectileData Params;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(ArenaHydraTags::SplineRunHydra);
	default CapabilityTags.Add(ArenaHydraTags::Action);
	USanctuaryBossSplineRunHydraActionComponent BossComp;
	ASanctuaryBossSplineRunHydra HydraOwner;

	FName SpitProjectileName = n"Tongue5";

	int ProjectilesToShoot;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HydraOwner = Cast<ASanctuaryBossSplineRunHydra>(Owner);
		BossComp = USanctuaryBossSplineRunHydraActionComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSanctuaryBossSplineRunHydraActionNodeShootProjectileData& ActivationParams) const
	{
		//if (DevToggleHydraPrototype::SplineRunLaunchWave.IsEnabled())
		//	return false;

		if (DevToggleHydraPrototype::SplineRunMachineGun.IsEnabled())
			return false;

		if (BossComp.Queue.Start(this, ActivationParams))
		{
			ActivationParams.ProjectileTarget = GetTargetActor();
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration < 2.0) // ish animation duration
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSanctuaryBossSplineRunHydraActionNodeShootProjectileData ActivationParams)
	{
		Params = ActivationParams;

		if (HydraOwner.ProjectileClass == nullptr)
			return;

		HydraOwner.DesiredAnimation = ESanctuaryBossSplineRunHydraAnimation::Projectile;
		Timer::SetTimer(this, n"DelayedProjectile", 0.5);
	}

	UFUNCTION()
	void DelayedProjectile()
	{
		if (!HydraOwner.bDoAttackLoop)
			return;

		USanctuaryBossSplineRunHydraEventHandler::Trigger_SpawnedGhostBall(Owner);

		FTransform ProjectileSpitTransform = HydraOwner.SkeletalMesh.GetSocketTransform(SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;

		if (HydraOwner.bBurstProjectiles)
			ProjectilesToShoot = 5;
		else
			ProjectilesToShoot = 1;

		FVector ToTarget = Params.ProjectileTarget.ActorLocation - LaunchLocation;
		auto Projectile = SpawnActor(HydraOwner.ProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		Projectile.TargetLocation = Params.ProjectileTarget.ActorLocation;
		Projectile.ProjectileTarget = Params.ProjectileTarget;

		FinishSpawningActor(Projectile);

		Timer::SetTimer(this, n"SpawnExtraProjectile", 0.2);
	}

	UFUNCTION()
	private void SpawnExtraProjectile()
	{
		ProjectilesToShoot--;

		if (ProjectilesToShoot <= 0)
			return;

		FTransform ProjectileSpitTransform = HydraOwner.SkeletalMesh.GetSocketTransform(SpitProjectileName);
		FVector LaunchLocation = ProjectileSpitTransform.Location;

		FVector ToTarget = Params.ProjectileTarget.ActorLocation - LaunchLocation;
		auto Projectile = SpawnActor(HydraOwner.ProjectileClass, LaunchLocation, ToTarget.ToOrientationRotator(), bDeferredSpawn = true);
		Projectile.TargetLocation = Params.ProjectileTarget.ActorLocation;
		Projectile.ProjectileTarget = Params.ProjectileTarget;
		
		Projectile.TargetOffset = FVector(Math::GetRandomPointInCircle_XY() * 2000.0);

		FinishSpawningActor(Projectile);

		Timer::SetTimer(this, n"SpawnExtraProjectile", 0.2);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossComp.Queue.Finish(this);
	}

	ASanctuaryBossSplineRunHydraProjectileTarget GetTargetActor() const
	{
		AHazePlayerCharacter TargetedPlayer = HydraOwner.bTargetZoe ? Game::Zoe : Game::Mio;
		if(TargetedPlayer.IsPlayerDead())
			TargetedPlayer = TargetedPlayer.OtherPlayer;

		FVector SplineRunDirection = FVector::ForwardVector;
		FVector PositionInFrontOfPlayer = TargetedPlayer.ActorLocation + SplineRunDirection * 2250.0;
		ASanctuaryBossSplineRunHydraProjectileTarget ClosestTarget;
		float ClosestDistance = MAX_flt;

		TListedActors<ASanctuaryBossSplineRunHydraProjectileTarget> ListedTargets;
		for (auto TargetActor : ListedTargets)
		{
			float Distance = (PositionInFrontOfPlayer - TargetActor.ActorLocation).Size();
			if (TargetActor.bWasLastTarget)
			{
				TargetActor.bWasLastTarget = false;
				continue;
			}
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestTarget = TargetActor;
			}
		}

		if (ClosestTarget != nullptr)
			ClosestTarget.bWasLastTarget = true;
		return ClosestTarget;
	}
}
