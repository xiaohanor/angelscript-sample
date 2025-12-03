class ASkylineSentryBossTile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USphereComponent HazardZone;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent SpawnPoint;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossHazardTileHazardCapability");
	
	UPROPERTY(DefaultComponent)
	USkylineSentryBossTileManagerComponent TileManager;

	UMaterial NormalMaterial;

	UPROPERTY(EditDefaultsOnly)
	bool bIsInactive;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FlipAnimation;

	UPROPERTY()
	UNiagaraSystem HazardNiagaraSystem;

	UPROPERTY(EditDefaultsOnly)
	UMaterial ChargeUpMaterial;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineSentryBossPulseTurret> PulseTurret;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineSentryBossMissileTurret> MissileTurret;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineSentryBossLaserDrone> LaserDrone;

	bool bIsHazardActivated;
	bool bIsTurretActivated;
	bool bIsSeekerActivated;


	ASKylineSentryBoss Boss;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		NormalMaterial = MeshComp.GetMaterial(0).BaseMaterial;
		FlipAnimation.BindUpdate(this, n"FlipAnimationUpdate");
		FlipAnimation.BindFinished(this, n"OnFlipAnimationFinished");
	}


	UFUNCTION()
	void FlipAnimationUpdate(float Value)
	{	
		MeshRoot.RelativeRotation = FRotator(0, Value * 180, 0);
	}

	UFUNCTION()
	void OnFlipAnimationFinished()
	{
		
		
	}

	void Flip()
	{
		FlipAnimation.Play();
	}

	void PrepareHazard()
	{
		bIsHazardActivated = true;

	}



	void SpawnMissileTurret()
	{
		AActor SpawnedActor = SpawnActor(MissileTurret, SpawnPoint.WorldLocation, ActorRotation + FRotator(0, 0, 90));
		ASkylineSentryBossMissileTurret SpawnedMissileTurret = Cast<ASkylineSentryBossMissileTurret>(SpawnedActor);

		SpawnedMissileTurret.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		SpawnedMissileTurret.Boss = Boss;
		
		Boss.ActiveMissileTurrets.Add(SpawnedMissileTurret);

	}

	void SpawnLaserDrone()
	{	

		if(Boss.ActiveLaserDrones.Num() >= Boss.TileManager.MaxActiveDrones)
			return;

		AActor SpawnedActor = SpawnActor(LaserDrone, SpawnPoint.WorldLocation, ActorRotation + FRotator(0, 0, 90), NAME_None, true);
		ASkylineSentryBossLaserDrone SpawnedDrone = Cast<ASkylineSentryBossLaserDrone>(SpawnedActor);

		SpawnedDrone.Boss = Boss;
		SpawnedDrone.SphericalMoveComp.SetOrigin(Boss.Root);
		
		FTransform SpawnTransform;
		SpawnTransform.Location = SpawnPoint.WorldLocation;
		SpawnTransform.Rotation = (ActorRotation + FRotator(0, 0, 90)).Quaternion();
		FinishSpawningActor(SpawnedActor, SpawnTransform);

		SpawnedDrone.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Boss.ActiveLaserDrones.Add(SpawnedDrone);
	}

	void SpawnPulseTurret()
	{
		if(Boss.ActivePulseTurrets.Num() >= Boss.TileManager.MaxActivePulseTurrets)
			return;

		AActor SpawnedActor = SpawnActor(PulseTurret, SpawnPoint.WorldLocation, ActorRotation, NAME_None, true);
		ASkylineSentryBossPulseTurret SpawnedPulseTurret = Cast<ASkylineSentryBossPulseTurret>(SpawnedActor);

		SpawnedPulseTurret.SphericalMoveComp.SetOrigin(Boss.Root);
		SpawnedPulseTurret.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		
		FTransform SpawnTransform;
		SpawnTransform.Location = SpawnPoint.WorldLocation;
		SpawnTransform.Rotation = ActorRotation.Quaternion();
		FinishSpawningActor(SpawnedActor, SpawnTransform);

		
		Boss.ActivePulseTurrets.Add(SpawnedPulseTurret);
	}


	UFUNCTION()
	private void OnSeekerDestroy(ASkylineSentryBossMissileTurret Turrets)
	{
		Boss.ActiveMissileTurrets.Remove(Turrets);
	}
};