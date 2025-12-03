event void FOnShootProjectileLaunched(ATundraTreeGuardianRangedShootProjectile Projectile);

UCLASS(Abstract)
class ATundraTreeGuardianRangedShootProjectileSpawner : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpawnLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTundraPlayerOtterSonarBlastTargetable SonarBlastTargetable;
	default SonarBlastTargetable.bLerpOutOnCircle = true;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ATundraTreeGuardianRangedShootProjectile> ProjectileClass;

	UPROPERTY(EditInstanceOnly)
	bool bBlockedFromStart = false;

	UPROPERTY()
	FOnShootProjectileLaunched OnShootProjectileLaunched;

	UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	ATundraTreeGuardianRangedShootProjectile CurrentProjectile;

	TOptional<float> TimeOfLaunch;
	bool bLaunch = false;
	TArray<FInstigator> SpawnerBlockers;

	UPROPERTY(EditInstanceOnly)
	const float ProjectileRespawnDuration = 5.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(ProjectileClass, this);
		SonarBlastTargetable.OnTriggered.AddUFunction(this, n"OnLaunch");
		
		if(bBlockedFromStart)
		{
			BlockSpawner(this);
			SonarBlastTargetable.Disable(this);
		}
		else
		{
			Spawn();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(Time::GetGameTimeSince(TimeOfLaunch.Value) < ProjectileRespawnDuration)
			return;

		if(IsSpawnerBlocked())
			return;

		Spawn();
		TimeOfLaunch.Reset();
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void OnLaunch(UTundraPlayerOtterSonarBlastTargetable Targetable)
	{
		if(bLaunch)
			return;

		if(!Game::Mio.HasControl())
			return;

		NetOnLaunch(CurrentProjectile);
	}

	UFUNCTION(NetFunction)
	private void NetOnLaunch(ATundraTreeGuardianRangedShootProjectile Projectile)
	{
		CurrentProjectile = Projectile;
		CurrentProjectile.LaunchBySpawner();
		TimeOfLaunch.Set(Time::GetGameTimeSeconds());
		if(HasControl())
			SetActorTickEnabled(true);

		bLaunch = true;
		SonarBlastTargetable.Disable(this);

		FTundraTreeGuardianRangedShootProjectileSpawnerOnLaunchEffectParams Params;
		Params.LaunchedProjectile = CurrentProjectile;
		UTreeGuardianRangedShootProjectileSpawnerVFXHandler::Trigger_OnLaunchProjectile(this, Params);

		OnShootProjectileLaunched.Broadcast(CurrentProjectile);
		
		/* Moved this one /Victor */
		CurrentProjectile = nullptr;
	}

	void Spawn()
	{
		if(!HasControl())
			return;

		if(CurrentProjectile != nullptr)
			return;

		FHazeActorSpawnParameters Params;
		Params.Location = SpawnLocation.WorldLocation;
		Params.Rotation = SpawnLocation.WorldRotation;
		auto Projectile = Cast<ATundraTreeGuardianRangedShootProjectile>(SpawnPool.SpawnControl(Params));
		CrumbOnSpawn(Projectile);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnSpawn(ATundraTreeGuardianRangedShootProjectile Projectile)
	{
		CurrentProjectile = Projectile;
		Projectile.Spawn(SpawnPool);
		bLaunch = false;
		SonarBlastTargetable.Enable(this);

		FTundraTreeGuardianRangedShootProjectileSpawnerOnSpawnEffectParams Params;
		Params.SpawnedProjectile = CurrentProjectile;
		UTreeGuardianRangedShootProjectileSpawnerVFXHandler::Trigger_OnSpawnProjectile(this, Params);
	}

	UFUNCTION()
	void BlockSpawner(FInstigator Instigator)
	{
		SpawnerBlockers.AddUnique(Instigator);
	}

	UFUNCTION()
	void UnblockSpawn(FInstigator Instigator)
	{
		SpawnerBlockers.RemoveSingleSwap(Instigator);
		Spawn();
	}

	UFUNCTION()
	void UnblockFromStartBlocked()
	{
		UnblockSpawn(this);
	}

	UFUNCTION(BlueprintPure)
	bool IsSpawnerBlocked() const
	{
		return SpawnerBlockers.Num() > 0;
	}
}