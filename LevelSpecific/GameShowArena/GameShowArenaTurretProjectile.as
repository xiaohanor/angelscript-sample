class AGameShowArenaTurretProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ExplosionFX;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent TrailFX;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DisplayDecalComp;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaPlatformArm ConnectedArm;

	UPROPERTY(EditAnywhere)
	FLinearColor Tint = FLinearColor::Red;

	UPROPERTY()
	UTexture2D Texture;
	
	UPROPERTY(EditAnywhere)
	bool bIsAlternateDecal;

	UMaterialInstanceDynamic DynamicMaterial;
	FRotator DecalRotation;
	float DecalOpacity = 0;

	UStaticMeshComponent PlatformMeshComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> ExplosionCameraShake;

	FHazeTimeLike MoveProjectileTimelike;
	default MoveProjectileTimelike.Duration = 0.2;

	bool bShouldTickDecalTimer = false;
	float DecalTimer = 0;
	float DecalTimerDuration = 0.75;

	FVector StartingLoc;
	FVector TargetLoc;
	FVector StartScale = FVector::OneVector * 150;
	FVector TargetScale = FVector::OneVector * 10;
	FVector CurrentScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveProjectileTimelike.BindUpdate(this, n"MoveProjectileTimelikeUpdate");
		MoveProjectileTimelike.BindFinished(this, n"MoveProjectileTimelikeFinished");
		TargetLoc = MeshRoot.WorldLocation;

		// Used for displaying a decal
		PlatformMeshComp = ConnectedArm.PlatformMesh;
		DisplayDecalComp.AssignTarget(PlatformMeshComp, ConnectedArm.PanelMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldTickDecalTimer)
		{
			DecalTimer += DeltaSeconds;
			if(DecalTimer >= DecalTimerDuration)
			{
				bShouldTickDecalTimer = false;
			}

			float Alpha = Math::Saturate(DecalTimer / DecalTimerDuration);
			CurrentScale = Math::Lerp(TargetScale, StartScale, Alpha);
			DecalOpacity = Math::Lerp(0, 80, Alpha);
		}

		DisplayDecalComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(PlatformMeshComp.WorldLocation, DecalRotation, CurrentScale, Texture, DecalOpacity, Tint), bIsAlternateDecal);
	}

	void ActivateDecal()
	{
		DecalTimer = 0;
		bShouldTickDecalTimer = true;
	}

	void ActivateProjectile(FVector ShootLocation)
	{
		Mesh.SetHiddenInGame(false);
		MeshRoot.SetWorldLocation(ShootLocation);
		StartingLoc = ShootLocation;
		MoveProjectileTimelike.PlayFromStart();
		TrailFX.Activate();
	}

	UFUNCTION()
	private void MoveProjectileTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetWorldLocation(Math::Lerp(StartingLoc, TargetLoc, CurrentValue));
	}

	UFUNCTION()
	private void MoveProjectileTimelikeFinished()
	{
		Mesh.SetHiddenInGame(true);
		TrailFX.DeactivateImmediate();
		ExplosionFX.Activate(true);
		DecalOpacity = 0;

		FGameShowArenaShootingArmProjectileData Data;
		Data.GameShowArenaTurretProjectile = this;
		UGameShowAnnouncerShootingArmEffectHandler::Trigger_ProjectileHit(this, Data);

		for (auto Player : Game::Players)
		{
			Player.PlayWorldCameraShake(ExplosionCameraShake, this, ActorLocation, 800.0, 5000.0);

			if (BoxCollision.IsOverlappingActor(Player))
				Player.KillPlayer();
		}
	}
};