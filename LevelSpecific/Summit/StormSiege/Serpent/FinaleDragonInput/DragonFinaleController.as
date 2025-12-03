class ADragonFinaleController : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShootOrigin;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer PlayerTarget;

	UPROPERTY(EditAnywhere)
	AFinaleProjectileActor FinaleProjectile;

	TSubclassOf<AFinaleProjectileActor> FinaleProjectileClass;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	void FireProjectile()
	{
		FinaleProjectile.ActivateProjectile();
		// AFinaleProjectileActor Projectile = SpawnActor(FinaleProjectileClass, ShootOrigin.WorldLocation, bDeferredSpawn = true);
		// Projectile.TargetLoc = TargetActor.ActorLocation;
		// FinishSpawningActor(Projectile);
	}
};