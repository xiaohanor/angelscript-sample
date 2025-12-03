class ASpaceWalkDebrisKill : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent KillMesh;
	default KillMesh.SetHiddenInGame(true);

	FVector AsteroidStartingLocation;

	FVector HalfSize = FVector(2500,2500,2500);

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASpaceWalkDebrisKillActor> DebrisSpawn;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		KillMesh.OnComponentBeginOverlap.AddUFunction(this, n"KillZone");
	}


	UFUNCTION()
	private void KillZone(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                      UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                      const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		ASpaceWalkDebrisKillActor SpawnDebris = Cast<ASpaceWalkDebrisKillActor> (SpawnActor(DebrisSpawn,Math::RandomPointInBoundingBox(ActorCenterLocation, HalfSize)));
		SpawnDebris.Launch(Player);
	}

};