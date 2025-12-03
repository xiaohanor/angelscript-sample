event void FOilRigDodgeProjectileScenarioCompletedEvent();

class AOilRigDodgeProjectileSpawner : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpawnerRoot;

	UPROPERTY(DefaultComponent, Attach = SpawnerRoot)
	USceneComponent TurretYawRoot;

	UPROPERTY(DefaultComponent, Attach = TurretYawRoot)
	USceneComponent TurretPitchRoot;

	UPROPERTY(DefaultComponent, Attach = TurretPitchRoot)
	USceneComponent MuzzleComp;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(EditInstanceOnly)
	AActor ShipCollisionActor;

	UPROPERTY(EditInstanceOnly)
	ADeathVolume ShipDeathVolume;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AOilRigDodgeProjectile> ProjectileClass;

	UPROPERTY()
	FOilRigDodgeProjectileScenarioCompletedEvent OnDodgeScenarioCompleted;

	float SpawnInterval = 3.0;

	bool bActive = false;

	int MioDodges = 0;
	int ZoeDodges = 0;

	int DodgesRequired = 3;

	bool bDodgesCompleted = false;
	int ProjectileSpawnCounter = 0;

	FTimerHandle MioSpawnTimerHandle;
	FTimerHandle ZoeSpawnTimerHandle;

	AHazePlayerCharacter NextTarget;

	float CurrentTurretYaw = 0.0;
	float CurrentTurretPitch = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetShipCollisionEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		FVector DirToTarget = (NextTarget.ActorLocation - TurretYawRoot.WorldLocation).GetSafeNormal();
		FRotator TargetRot = DirToTarget.Rotation();

		CurrentTurretYaw = Math::FInterpTo(CurrentTurretYaw, TargetRot.Yaw, DeltaTime, 5.0);
		CurrentTurretPitch = Math::FInterpTo(CurrentTurretPitch, TargetRot.Pitch, DeltaTime, 5.0);

		TurretYawRoot.SetWorldRotation(FRotator(TurretYawRoot.WorldRotation.Pitch, CurrentTurretYaw, TurretYawRoot.WorldRotation.Roll));
		TurretPitchRoot.SetWorldRotation(FRotator(CurrentTurretPitch, TurretPitchRoot.WorldRotation.Yaw, TurretPitchRoot.WorldRotation.Roll));
	}

	UFUNCTION()
	void ActivateSpawner()
	{
		if (bActive)
			return;

		bActive = true;

		Timer::SetTimer(this, n"SpawnInitialMioProjectile", 1.5);
		Timer::SetTimer(this, n"SpawnInitialZoeProjectile", 3.0);

		NextTarget = Game::Mio;
		CurrentTurretYaw = TurretYawRoot.WorldRotation.Yaw;
		CurrentTurretPitch = TurretPitchRoot.WorldRotation.Pitch;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
			if (Player.IsMio())
				HealthComp.OnDeathTriggered.AddUFunction(this, n"MioDied");
			else
				HealthComp.OnDeathTriggered.AddUFunction(this, n"ZoeDied");

			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.OnPlayerRespawned.AddUFunction(this, n"PlayerRespawned");
		}

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void SpawnInitialMioProjectile()
	{
		SpawnMioProjectile();
		MioSpawnTimerHandle = Timer::SetTimer(this, n"SpawnMioProjectile", SpawnInterval, true);
	}

	UFUNCTION()
	private void SpawnInitialZoeProjectile()
	{
		SpawnZoeProjectile();
		ZoeSpawnTimerHandle = Timer::SetTimer(this, n"SpawnZoeProjectile", SpawnInterval, true, 1.5);
	}

	UFUNCTION()
	private void MioDied()
	{
		MioSpawnTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION()
	private void ZoeDied()
	{
		ZoeSpawnTimerHandle.ClearTimerAndInvalidateHandle();
	}

	UFUNCTION()
	private void PlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if (RespawnedPlayer.IsMio())
			Timer::SetTimer(this, n"ResetMioTimer", 1.0, false);
		if (RespawnedPlayer.IsZoe())
			Timer::SetTimer(this, n"ResetZoeTimer", 1.0, false);
	}

	UFUNCTION()
	void ResetMioTimer()
	{
		if (bDodgesCompleted)
			return;

		SpawnMioProjectile();
		MioSpawnTimerHandle = Timer::SetTimer(this, n"SpawnMioProjectile", SpawnInterval, true);
	}

	UFUNCTION()
	void ResetZoeTimer()
	{
		if (bDodgesCompleted)
			return;

		SpawnZoeProjectile();
		ZoeSpawnTimerHandle = Timer::SetTimer(this, n"SpawnZoeProjectile", SpawnInterval, true);
	}

	UFUNCTION()
	void DeactivateSpawner()
	{
		if (!bActive)
			return;

		bActive = false;

		MioSpawnTimerHandle.ClearTimerAndInvalidateHandle();
		ZoeSpawnTimerHandle.ClearTimerAndInvalidateHandle();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
			HealthComp.OnDeathTriggered.UnbindObject(this);

			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
			RespawnComp.OnPlayerRespawned.UnbindObject(this);
		}
	}

	UFUNCTION()
	private void SpawnMioProjectile()
	{
		SpawnProjectile(Game::Mio);
	}

	UFUNCTION()
	private void SpawnZoeProjectile()
	{
		SpawnProjectile(Game::Zoe);
	}

	UFUNCTION()
	private void SpawnProjectile(AHazePlayerCharacter Player)
	{
		if (bDodgesCompleted)
			return;

		if (HasControl())
		{
			if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
				return;

			NetSpawnProjectile(Player);
		}
	}

	UFUNCTION(NetFunction)
	private void NetSpawnProjectile(AHazePlayerCharacter ProjectileTarget)
	{
		AOilRigDodgeProjectile Projectile = SpawnActor(ProjectileClass, MuzzleComp.WorldLocation, bDeferredSpawn = true);
		ProjectileSpawnCounter++;
		Projectile.MakeNetworked(this, ProjectileSpawnCounter);
		Projectile.SetActorControlSide(ProjectileTarget);
		FinishSpawningActor(Projectile);
		Projectile.LaunchProjectile(ProjectileTarget);
		Projectile.OnDodged.AddUFunction(this, n"ProjectileDodged");

		FOilRigDodgeProjectileParams Params;
		Params.Player = ProjectileTarget;
		UOilRigDodgeProjectileSpawnerEventHandler::Trigger_ShotFired(this, Params);

		NextTarget = ProjectileTarget.OtherPlayer;

		BP_SpawnProjectile();
	}

	UFUNCTION(BlueprintEvent)
	void BP_SpawnProjectile() {}

	UFUNCTION()
	private void ProjectileDodged(AHazePlayerCharacter Player)
	{
		if (bDodgesCompleted)
			return;

		if (Player.HasControl())
			NetProjectileDodged(Player);
	}

	UFUNCTION(NetFunction)
	private void NetProjectileDodged(AHazePlayerCharacter Player)
	{
		if (bDodgesCompleted)
			return;

		if (Player.IsMio())
			MioDodges++;
		if (Player.IsZoe())
			ZoeDodges++;

		if (MioDodges >= DodgesRequired && ZoeDodges >= DodgesRequired)
		{
			CompleteDodgeTutorial();
		}

		FOilRigDodgeProjectileParams Params;
		Params.Player = Player;
		UOilRigDodgeProjectileSpawnerEventHandler::Trigger_DashSuccessful(this, Params);
	}

	UFUNCTION(DevFunction)
	void CompleteDodgeTutorial()
	{
		DeactivateSpawner();
		bDodgesCompleted = true;
		OnDodgeScenarioCompleted.Broadcast();
	}

	UFUNCTION()
	void ShipsCollide()
	{
		UOilRigDodgeProjectileSpawnerEventHandler::Trigger_ShipsCollide(this);
	}

	UFUNCTION()
	void ShipCrashed()
	{
		UOilRigDodgeProjectileSpawnerEventHandler::Trigger_ShipCrash(this);
	}

	UFUNCTION()
	void EnableShipCollision()
	{
		ShipDeathVolume.DisableDeathVolume(this);
		ShipCollisionActor.SetActorEnableCollision(true);
		
		SetShipCollisionEnabled(true);
	}

	void SetShipCollisionEnabled(bool bEnabled)
	{
		TArray<AActor> AttachedBlockingVolumes;
		ShipCollisionActor.GetAttachedActors(AttachedBlockingVolumes);
		for (AActor BlockingVolume : AttachedBlockingVolumes)
		{
			BlockingVolume.SetActorEnableCollision(bEnabled);
		}
	}
}

class UOilRigDodgeProjectileSpawnerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void ShotFired(FOilRigDodgeProjectileParams Params) {}

	UFUNCTION(BlueprintEvent)
	void DashSuccessful(FOilRigDodgeProjectileParams Params) {}

	UFUNCTION(BlueprintEvent)
	void ShipsCollide() {}

	UFUNCTION(BlueprintEvent)
	void ShipCrash() {}
}

struct FOilRigDodgeProjectileParams
{
	UPROPERTY()
	AHazePlayerCharacter Player;
}