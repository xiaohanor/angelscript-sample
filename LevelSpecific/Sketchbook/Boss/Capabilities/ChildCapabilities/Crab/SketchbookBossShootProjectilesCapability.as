class USketchbookBossShootProjectilesCapability : USketchbookCrabBossChildCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	float LastProjectileSpawnTime;
	float TimeBetweenProjectiles = 1.3;

	int ProjectilesSpawned = 0;
	const int ProjectilesToSpawn = 10;

	int LastLaneIndex = 0;
	const float LaneSpacing = 150;
	const float ProjectileFiringVerticalOffset = 0;

	bool bTargetingLeftSide;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(CrabComp.SubPhase != ESketchbookCrabBossSubPhase::Shoot)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ProjectilesSpawned >= ProjectilesToSpawn)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ProjectilesSpawned = 0;

		//Add some extra distance to make sure the projectile travels completely off screen before destroying
		float RightSide = Boss.GetArenaRightSide() + 500;
		float LeftSide = Boss.GetArenaLeftSide() - 500;

		bTargetingLeftSide = (Math::Abs(Owner.ActorLocation.Y - LeftSide) > Math::Abs(Owner.ActorLocation.Y - RightSide));

		CrabComp.TargetProjectilePositionY = bTargetingLeftSide ? LeftSide : RightSide;

		const float TargetYaw = bTargetingLeftSide ? CrabComp.ProjectileFiringYaw : -CrabComp.ProjectileFiringYaw;
		FQuat TargetRotation = FQuat::MakeFromEuler(FVector::UpVector * TargetYaw);
		Boss.RotateTowards(TargetRotation, InterpSpeed = 9999999999);
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
		if(ActiveDuration < 1)
			return;

		if(Time::GetGameTimeSince(LastProjectileSpawnTime) >= TimeBetweenProjectiles)
			SpawnProjectile();
	}

	void SpawnProjectile()
	{
		int NewLaneIndex = Math::WrapIndex(LastLaneIndex + 1, 0, 2);
		LastLaneIndex = NewLaneIndex;

		float TargetZ = Boss.ProjectileSpawnPoint.WorldLocation.Z + ProjectileFiringVerticalOffset;
		if(NewLaneIndex == 0)
			TargetZ += LaneSpacing;

		ProjectilesSpawned++;
		LastProjectileSpawnTime = Time::GameTimeSeconds;

		const FName BoneName = NewLaneIndex == 0 ? n"LeftClaw" : n"RightClaw";
		const FVector ClawLocationWS = Boss.Mesh.GetSocketLocation(BoneName);

		const FVector SpawnLocationWS = FVector(
			Boss.ProjectileSpawnPoint.WorldLocation.X, 
			ClawLocationWS.Y + Math::Sign(Owner.ActorForwardVector.Y) * 50, 
			TargetZ
		);

		auto ProjectileActor = SpawnActor(Boss.ProjectileClass, SpawnLocationWS);
		ASketchbookBossCrabProjectile Projectile = Cast<ASketchbookBossCrabProjectile>(ProjectileActor);

		const float LaneTargetY = Boss.ProjectileSpawnPoint.WorldLocation.Y + (bTargetingLeftSide ? -LaneSpacing : LaneSpacing);
		Projectile.TargetLaneLocation = FVector(0, LaneTargetY, TargetZ);
		Projectile.TargetOffscreenLocation = FVector(0, CrabComp.TargetProjectilePositionY, TargetZ);

		Boss.Mesh.SetAnimTrigger(n"ShootProjectile");
		Boss.Mesh.SetAnimIntParam(n"ProjectileLaneIndex", NewLaneIndex);
	}
};