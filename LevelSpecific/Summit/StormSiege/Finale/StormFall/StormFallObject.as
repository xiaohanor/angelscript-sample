class AStormFallObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> Meshes;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditAnywhere)
	float MaxSpeed = 1500.0;
	UPROPERTY(EditAnywhere)
	float MinSpeed = 1200.0;
	float MoveSpeed;

	UPROPERTY(EditAnywhere)
	float LifeDuration = 8.0;
	float LifeTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveSpeed = Math::RandRange(MinSpeed, MaxSpeed);
		LifeTime = Time::GameTimeSeconds + LifeDuration;
	}

	void InitializeObject()
	{
		float Noise = Math::PerlinNoise1D(Time::GameTimeSeconds);
		int Index = Math::RoundToInt(Math::GetMappedRangeValueClamped(FVector2D(-1, 1), FVector2D(0, Meshes.Num() - 1), Noise));
		MeshComp.StaticMesh = Meshes[Index];
	}

	void RandRangeInitializeObject()
	{
		int Index = Math::RandRange(0, Meshes.Num() - 1);
		MeshComp.StaticMesh = Meshes[Index];
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > LifeTime)
			DestroyActor();

		ActorLocation += FVector::UpVector * MoveSpeed * DeltaSeconds;
	}
}