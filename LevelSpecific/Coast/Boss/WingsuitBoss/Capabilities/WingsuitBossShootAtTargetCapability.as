struct FWingsuitBossShootAtTargetActivatedParams
{
	FWingsuitBossShootAtTargetData TargetData;
}

class UWingsuitBossShootAtTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AWingsuitBoss Boss;
	UHazeActorLocalSpawnPoolComponent SpawnPool;
	UWingsuitBossSettings Settings;
	FWingsuitBossShootAtTargetData TargetData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Boss = Cast<AWingsuitBoss>(Owner);
		SpawnPool = HazeActorLocalSpawnPoolStatics::GetOrCreateSpawnPool(Boss.ShootAtTargetClass, Boss);
		Settings = UWingsuitBossSettings::GetSettings(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FWingsuitBossShootAtTargetActivatedParams& Params) const
	{
		if(Boss.QueuedShootAtTargets.Num() == 0)
			return false;

		if(DeactiveDuration < Settings.ShootAtTargetSpawnCooldown)
			return false;

		Params.TargetData = Boss.QueuedShootAtTargets[0];
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration >= Settings.ShootAtTargetShootDelay)
			return true;

		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FWingsuitBossShootAtTargetActivatedParams Params)
	{
		Boss.BlockCapabilities(WingsuitBossTags::WingsuitBossAttack, this);
		Boss.OverrideRotationSpringStiffness.Apply(Settings.ShootAtTargetOverrideRotationSpringStiffness, this, EInstigatePriority::High);

		if(HasControl())
			Boss.QueuedShootAtTargets.RemoveAt(0);
		
		Boss.SetTurretTargetWorldLocation(TargetData.TargetLocation, true);
		Boss.SetTurretTargetWorldLocation(TargetData.TargetLocation, false);
		TargetData = Params.TargetData;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.UnblockCapabilities(WingsuitBossTags::WingsuitBossAttack, this);
		Boss.BlockWeaponsForDuration(1.5, this);
		Boss.OverrideTargetRotation.Clear(this);
		Boss.OverrideRotationSpringStiffness.Clear(this);
		SpawnProjectile();
		Boss.ResetTurretRotation(true);
		Boss.ResetTurretRotation(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Boss.OverrideTargetRotation.Apply(FRotator::MakeFromXZ(TargetData.TargetLocation - Boss.ActorLocation, FVector::UpVector), this, EInstigatePriority::High);
	}

	void SpawnProjectile()
	{
		FHazeActorSpawnParameters Params;
		Params.Location = Boss.Mesh.GetSocketLocation(n"RightLowerTurretMuzzle");
		Params.Rotation = FRotator::MakeFromXZ(TargetData.TargetLocation - Params.Location, FVector::UpVector);
		Params.Spawner = Boss;
		auto Projectile = Cast<AWingsuitBossShootAtTargetProjectile>(SpawnPool.Spawn(Params));
		Projectile.Spawn(TargetData, Settings);
		UWingsuitBossEffectHandler::Trigger_OnShootRocket(Boss);
	}
}