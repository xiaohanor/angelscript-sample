UCLASS(Abstract)
class USandHandPlayerComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadWrite, DisplayName = Settings, Category = Aiming)
	FAimingSettings AimSettings;
	default AimSettings.bShowCrosshair = true;
	default AimSettings.OverrideAutoAimTarget = USandHandAutoAimTargetComponent;
	default AimSettings.bCrosshairFollowsTarget = true;
	default AimSettings.bApplyAimingSensitivity = false;

	UPROPERTY(Category = Shooting)
	TSubclassOf<ASandHandProjectile> SandHandProjectileClass;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ChargeCameraSettings;

	UHazeActorNetworkedSpawnPoolComponent ProjectilePool = nullptr;
	ASandHandProjectile CurrentProjectile;

	AHazePlayerCharacter Player;

	bool bSandHandQueued;
	bool bSandHandHasShot;
	bool bSandHandLeft;
	uint SandHandThrowFrame;

	// If this is assigned, use forward of this as aim direction
	// Used in Sandfish Tunnel
	UHazeSplineComponent AimSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		// Create pool
		ProjectilePool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(SandHandProjectileClass, Player);
		ProjectilePool.OnSpawnedBySpawner.FindOrAdd(this).AddUFunction(this, n"OnSandHandProjectileSpawned");
	}

	ASandHandProjectile ReadyProjectile_Control()
	{
		return Cast<ASandHandProjectile>(ProjectilePool.SpawnControl(FHazeActorSpawnParameters(this)));
	}

	UFUNCTION()
	private void OnSandHandProjectileSpawned(AHazeActor SpawnedActor, FHazeActorSpawnParameters Params)
	{
		CurrentProjectile = Cast<ASandHandProjectile>(SpawnedActor);

		CurrentProjectile.SetActorControlSide(Player);

		CurrentProjectile.OnCollisionEvent.AddUFunction(this, n"OnProjectileCollision");

		CurrentProjectile.Activate();

		const float InitialScale = 0.01;
		CurrentProjectile.Mesh.SetRelativeScale3D(FVector(InitialScale, bSandHandLeft ? -InitialScale : InitialScale, InitialScale));

		const FName AttachSocket = bSandHandLeft ? n"LeftAttach" : n"RightAttach";
		CurrentProjectile.AttachToComponent(Player.Mesh, AttachSocket);

		CurrentProjectile.Mesh.ResetPose();

		FSandHandSpawnedData SpawnedData;
		SpawnedData.bLeft = bSandHandLeft;
		SpawnedData.SandHandProjectile = CurrentProjectile;
		USandHandEventHandler::Trigger_OnSandHandSpawned(Player, SpawnedData);
	}

	void DismissCurrentProjectile(bool bRecycleProjectile)
	{
		if (CurrentProjectile == nullptr)
			return;

		if (bRecycleProjectile)
		{
			CurrentProjectile.Deactivate();

			FSandHandRecycleData RecycleData;
			RecycleData.SandHandProjectile = CurrentProjectile;
			USandHandEventHandler::Trigger_OnSandHandRecycled(Player, RecycleData);

			ProjectilePool.UnSpawn(CurrentProjectile);
		}

		CurrentProjectile = nullptr;
	}

	UFUNCTION()
	private void OnProjectileCollision(FSandHandHitData HitData)
	{
		USandHandEventHandler::Trigger_OnSandHandProjectileHit(Player, HitData);
		
		// Recycle projectile
		if (ProjectilePool != nullptr)
		{
			// PlayerSandHandComponent.ProjectilePool.RecycleSandHandProjectile(HitData.SandHandProjectile);
			HitData.SandHandProjectile.Deactivate();
			
			FSandHandRecycleData RecycleData;
			RecycleData.SandHandProjectile = HitData.SandHandProjectile;
			USandHandEventHandler::Trigger_OnSandHandRecycled(Player, RecycleData);

			ProjectilePool.UnSpawn(HitData.SandHandProjectile);
			if(CurrentProjectile == HitData.SandHandProjectile)
				CurrentProjectile = nullptr;
		}
	}


	bool IsUsingSandHands() const
	{
		if(Player.IsAnyCapabilityActive(SandHand::Tags::SandHandInputCapability))
			return true;

		if(bSandHandQueued)
			return true;

		if(Player.IsAnyCapabilityActive(SandHand::Tags::SandHandShootCapability))
			return true;

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool ShotThisFrame() const
	{
		return SandHandThrowFrame == Time::FrameNumber;
	}
}