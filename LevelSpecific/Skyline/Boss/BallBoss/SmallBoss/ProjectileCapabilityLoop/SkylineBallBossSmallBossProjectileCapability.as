struct FSkylineBallBossSmallBossProjectileData
{
	FVector SpawnLocation;
	FVector TargetLocation;
	bool bCanProjectile = false;
}

class USkylineBallBossSmallBossProjectileCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(SkylineBallBossTags::SmallBoss);
	default CapabilityTags.Add(SkylineBallBossTags::Action);

	ASkylineBallBossSmallBoss SmallBoss;
	USkylineBallBossSmallBossProjectileActionComponent BossComp;

	float TargetRadius = 500.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(Owner);
		BossComp = USkylineBallBossSmallBossProjectileActionComponent::GetOrCreate(Owner);
		ASkylineBallBossSmallBossProjectile TempProjectile = Cast<ASkylineBallBossSmallBossProjectile>(ASkylineBallBossSmallBossProjectile.GetDefaultObject());
		TargetRadius = TempProjectile.TargetRadius;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossSmallBossProjectileData& ActivationParams) const
	{
		if (SmallBoss.ProjectileTargetPlayer != nullptr)
		{
			ActivationParams.SpawnLocation = SmallBoss.RollRoot.WorldLocation;
			ActivationParams.bCanProjectile = CanProjectile();
			if (ActivationParams.bCanProjectile)
				ActivationParams.TargetLocation = StartFindTargetLocation(SmallBoss.ProjectileTargetPlayer.ActorLocation);
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossSmallBossProjectileData ActivationParams)
	{
		SmallBoss.ProjectileTargetPlayer = nullptr;
		bool bFoundTarget = !ActivationParams.TargetLocation.Equals(FVector());
		if (bFoundTarget)
		{
			auto SpawnedProjectile = SpawnActor(SmallBoss.ProjectileClass, ActivationParams.SpawnLocation, bDeferredSpawn = true);
			SpawnedProjectile.TargetLocation = ActivationParams.TargetLocation;
			FinishSpawningActor(SpawnedProjectile);
			SmallBoss.BP_SpawnedProjectile();
			FSkylineSmallBossShootMissilesEventHandlerParams EventParams;
			EventParams.TargetLocation = ActivationParams.TargetLocation;
			USkylineSmallBossMiscVOEventHandler::Trigger_SmallBossShootMissile(SmallBoss, EventParams);
		}
	}

	private FVector StartFindTargetLocation(FVector PlayerLocation) const
	{
		int Depth = 0;
		return FindTargetLocation(Depth, PlayerLocation);
	}

	private FVector FindTargetLocation(int& Depth, FVector PlayerLocation) const
	{
		Depth++;
		FVector StartLocation = Math::GetRandomPointInCircle_XY() * TargetRadius + PlayerLocation;
		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(StartLocation, StartLocation - FVector::UpVector * 1000.0);

		if (HitResult.bBlockingHit)
			return HitResult.Location;
		else if (Depth > 20)
			return FVector();
		else
			return FindTargetLocation(Depth, PlayerLocation);
	}

	bool CanProjectile() const
	{
		if (!SmallBoss.bActive)
			return false;

		if (SmallBoss.bWeak)
			return false;

		if (SmallBoss.bLaserActive)
			return false;
		return true;
	}
};