class USketchbookBossDiagonalProjectileCapability : USketchbookDemonBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);


	const float TimeBetweenProjectiles = 0.2;
	const float TimeBetweenWaves = 0.1;
	const int ProjectilesPerWave = 15;
	const int WavesToSpawn = 3;
	const float Spacing = 300;

	float LastProjectileSpawnTime;
	float LastWaveTime;
	int WavesSpawned = 0;
	int ProjectilesSpawned = 0;
	FVector ProjectileDirection;

	bool bTargetingLeftSide;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(DemonComp.SubPhase != ESketchbookDemonBossSubPhase::Shoot)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WavesSpawned >= WavesToSpawn)
			return true;

		return false;
	} 

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProjectilesSpawned = 0;
		WavesSpawned = 0;

		const float RightSide = Boss.GetArenaRightSide();
		const float LeftSide = Boss.GetArenaLeftSide();

		bTargetingLeftSide = (Math::Abs(Owner.ActorLocation.Y - LeftSide) < Math::Abs(Owner.ActorLocation.Y - RightSide));
		ProjectileDirection = (FVector::DownVector * 3 + FVector::LeftVector).GetSafeNormal();
		if(bTargetingLeftSide)
			ProjectileDirection = (FVector::DownVector * 3 + FVector::RightVector).GetSafeNormal();


		const float TargetYaw = bTargetingLeftSide ? -DemonComp.ProjectileFiringYaw : DemonComp.ProjectileFiringYaw;
		FQuat TargetRotation = FQuat::MakeFromEuler(FVector::UpVector * TargetYaw);
		Boss.RotateTowards(TargetRotation);

		LastProjectileSpawnTime = Time::GameTimeSeconds;

		USketchbookBossEffectEventHandler::Trigger_OnAttack(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.EndMainAttackSequence();
		Boss.Idle(1);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSince(LastWaveTime) < TimeBetweenWaves)
			return;

		if(Time::GetGameTimeSince(LastProjectileSpawnTime) >= TimeBetweenProjectiles)
		{
			SpawnProjectile();
		}
	}

	void SpawnProjectile()
	{
		const FVector SpawnLocation = GetProjectileSpawnLocation(ProjectilesSpawned);
		auto ProjectileActor = SpawnActor(Boss.ProjectileClass, SpawnLocation, Boss.ProjectileSpawnPoint.WorldRotation);
		ASketchbookBossDemonProjectile Projectile = Cast<ASketchbookBossDemonProjectile>(ProjectileActor);
		Projectile.TargetLocation = GetProjectileTargetLocation(SpawnLocation);
		Projectile.SetActorRotation(FQuat::MakeFromZX(ProjectileDirection, FVector::ForwardVector));

		LastProjectileSpawnTime = Time::GameTimeSeconds;
		ProjectilesSpawned += 1;
		if(ProjectilesSpawned >= ProjectilesPerWave)
		{
			ProjectilesSpawned = 0;
			++WavesSpawned;
			LastWaveTime = Time::GameTimeSeconds;
		}	
	}

	FVector GetProjectileSpawnLocation(int ProjectileIndex) const
	{
		float SideOfScreen = Boss.GetArenaRightSide() + 1000;
		if(bTargetingLeftSide)
			SideOfScreen = Boss.GetArenaLeftSide() - 1000;

		int Multiplier = bTargetingLeftSide ? 1 : -1;
		FVector ProjectileStartLocation = FVector(0, SideOfScreen + Spacing * ProjectileIndex * Multiplier, Owner.ActorLocation.Z + 800);
		float Offset = Spacing / 2 * (WavesSpawned % 2);
		ProjectileStartLocation.Y += Offset * Multiplier;
		return ProjectileStartLocation;
	}

	FVector GetProjectileTargetLocation(FVector StartLocation) const
	{
		const FPlane BottomPlane = FPlane(FVector(0, 0, Boss.ArenaFloorZ), FVector::DownVector);
		return Math::RayPlaneIntersection(StartLocation, ProjectileDirection, BottomPlane);
	}
};