class ASummitDarkCaveMetalSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ProjectileOrigin;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
	default Visual.SpriteName = "SkullAndBones";
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitDarkCaveMetalPileShootCapability");

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY()
	TSubclassOf<ASummitDarkCaveMetalSlowProjectile> MetalSlowProjectileClass;

	TArray<AHazePlayerCharacter> PlayersInRange;

	UPROPERTY(EditAnywhere)
	float FireRate = 1.0;
	UPROPERTY(EditAnywhere)
	float WaitTime = 4.0;
	UPROPERTY(EditAnywhere)
	int RoundsPerAttack = 3;

	UPROPERTY(EditAnywhere)
	float KillRadius = 150.0;

	float PointLightIntensityTarget;

	bool bCanSpawn = true;

	FHazeAcceleratedFloat AccelFloat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccelFloat.AccelerateTo(PointLightIntensityTarget, 1.5, DeltaSeconds);	
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		PlayersInRange.AddUnique(Player);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		PlayersInRange.Remove(Player);
	}

	void SpawnProjectile()
	{
		FVector StartingFwdDir = ProjectileOrigin.ForwardVector;
		float RandomRightAdd = Math::RandRange(-1.0, 1.0);
		StartingFwdDir += ProjectileOrigin.RightVector * RandomRightAdd;
		StartingFwdDir.Normalize();
		auto Projectile = SpawnActor(MetalSlowProjectileClass, ProjectileOrigin.WorldLocation, StartingFwdDir.Rotation());

		if (PlayersInRange.Num() > 0)
		{
			if (PlayersInRange.Contains(Game::Zoe))
				Projectile.InitiateTarget(Game::Zoe);
			else
				Projectile.InitiateTarget(PlayersInRange[0]);
		}
	}

	UFUNCTION()
	void SetNewFireData(float NewFireRate, float NewWaitTime, int NewRoundsPerAttack)
	{
		FireRate = NewFireRate;
		WaitTime = NewWaitTime;
		RoundsPerAttack = NewRoundsPerAttack;
	}

	UFUNCTION()
	void EnableSpawning()
	{
		bCanSpawn = true;
	}

	UFUNCTION()
	void DisableSpawning()
	{
		bCanSpawn = false;
	}

	bool HasTargets()
	{
		return PlayersInRange.Num() > 0;
	}
};