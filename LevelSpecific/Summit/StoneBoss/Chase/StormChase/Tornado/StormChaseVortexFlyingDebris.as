class AStormChaseVortexFlyingDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UAdultDragonTakeDamageDestructibleRocksComponent DestructibleRocksComp;

	UPROPERTY(EditInstanceOnly)
	AActor VortexTarget;

	UPROPERTY(EditAnywhere)
	int SpeedMultiplier = 1;
	float Speed = 5000.0;

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> Meshes;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 120000;

	FRotator RandomRotation;
	float RandomRotSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UStormChaseVortexFlyingDebrisEventHandler::Trigger_OnVortexDebrisEventStart(this);

		RandomRotSpeed = Math::RandRange(15, 50);
		RandomRotation = FRotator(Math::RandRange(-1, 1), Math::RandRange(-1, 1), Math::RandRange(-1, 1));
	
		DestructibleRocksComp.OnDestructibleRockHit.AddUFunction(this, n"OnDestructibleRockHit");
	}

	UFUNCTION(CallInEditor)
	void RandomizeMesh()
	{
		int RandomMeshIndex = Math::RandRange(0, Meshes.Num() - 1);
		MeshComp.SetStaticMesh(Meshes[RandomMeshIndex]);
	}

	UFUNCTION()
	private void OnDestructibleRockHit(USceneComponent HitComponent, AHazePlayerCharacter Player)
	{
		AddActorDisable(this);
		UStormChaseVortexFlyingDebrisEventHandler::Trigger_OnVortexDebrisPlayerImpact(this, FStormChaseVortexFlyingDebrisParams(ActorLocation));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshComp.AddWorldRotation(RandomRotation * RandomRotSpeed * DeltaSeconds);

		FVector ForwardToCenter = (VortexTarget.ActorLocation - ActorLocation);
		float DistanceToMaintain = ForwardToCenter.Size();
		ForwardToCenter.Normalize();
		FVector RightVector = ForwardToCenter.CrossProduct(FVector::UpVector).GetSafeNormal();
		FVector ProjectedLocation = ActorLocation + RightVector * Speed * DeltaSeconds;
		FVector DirectionToProjected = (ProjectedLocation - VortexTarget.ActorLocation).GetSafeNormal();
		FVector TargetLocation = VortexTarget.ActorLocation + DirectionToProjected * DistanceToMaintain;
		FVector DirectionToTarget = (TargetLocation - ActorLocation).GetSafeNormal();
		ActorLocation += DirectionToTarget * Speed * SpeedMultiplier * DeltaSeconds;
	}
};