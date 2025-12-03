class ARedSpaceVortex : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default ActorHiddenInGame = true;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent VortexRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike SpawnTimeLike;

	bool bFullySpawned = false;

	bool bDespawning = false;

	bool bGameOverActive = false;

	FHazeAcceleratedFloat AccCrushSpeed;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh CubeMesh;

	int CubeAmount = 1000;

	UPROPERTY()
	TArray<UStaticMeshComponent> Cubes;
	
	float CurrentRadius = 100000.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Cubes.Empty();

		for (int i = 0; i <= CubeAmount; i++)
		{
			UStaticMeshComponent MeshComp = UStaticMeshComponent::Create(this);
			MeshComp.SetStaticMesh(CubeMesh);
			FVector CubeDir = FVector::ForwardVector.RotateAngleAxis(Math::RandRange(0.0, 360.0), FVector::UpVector);
			MeshComp.SetRelativeLocation(CubeDir * CurrentRadius);
			MeshComp.SetRelativeRotation(Math::RandomRotator(true));
			MeshComp.SetRelativeScale3D(FVector(0.5));
			MeshComp.AttachToComponent(VortexRoot, NAME_None, EAttachmentRule::KeepWorld);
			MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			Cubes.Add(MeshComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnTimeLike.BindUpdate(this, n"UpdateSpawn");
		SpawnTimeLike.BindFinished(this, n"FinishSpawn");
	}

	UFUNCTION(DevFunction)
	void Spawn()
	{
		SpawnTimeLike.PlayFromStart();
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	private void UpdateSpawn(float CurValue)
	{
		CurrentRadius = Math::Lerp(100000, 8000.0, CurValue);

		for (UStaticMeshComponent MeshComp : Cubes)
		{
			FVector DirToCube = (MeshComp.WorldLocation - VortexRoot.WorldLocation).GetSafeNormal();
			MeshComp.SetWorldLocation(VortexRoot.WorldLocation + (DirToCube * CurrentRadius));
		}
	}

	UFUNCTION()
	private void FinishSpawn()
	{
		bFullySpawned = true;
	}

	UFUNCTION()
	void Despawn()
	{
		bDespawning = true;

		SpawnTimeLike.ReverseFromEnd();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		VortexRoot.AddLocalRotation(FRotator(0.0, 100 * DeltaTime, 0.0));

		AHazePlayerCharacter FurthestPlayer = GetDistanceTo(Game::Mio) < GetDistanceTo(Game::Zoe) ? Game::Zoe : Game::Mio;
		float FurthestPlayerDist = GetDistanceTo(FurthestPlayer);

		if (!bGameOverActive && FurthestPlayerDist >= CurrentRadius)
		{
			TriggerGameOver();
		}

		if (bFullySpawned && !bDespawning)
		{
			CurrentRadius -= 800.0 * DeltaTime;
			for (UStaticMeshComponent MeshComp : Cubes)
			{
				FVector DirToCube = (MeshComp.WorldLocation - VortexRoot.WorldLocation).GetSafeNormal();
				MeshComp.SetWorldLocation(VortexRoot.WorldLocation + (DirToCube * CurrentRadius));
				MeshComp.AddLocalRotation(FRotator(360.0 * DeltaTime));
			}
		}
	}

	void TriggerGameOver()
	{
		bGameOverActive = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(n"Respawn", this);
			Player.KillPlayer();
		}

		PlayerHealth::TriggerGameOver();
	}
}