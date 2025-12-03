class ASkylineWaveGrid : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USkylineWaveComponent WaveComponent;

	UPROPERTY(EditAnywhere)
	FIntVector Size = FIntVector(12, 12, 1);

	UPROPERTY(EditAnywhere)
	float Spacing = 500.0;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AActor> ActorClass;

	TArray<AActor> Actors;

	TArray<FTransform> InitialRelativeTransforms;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto Actor : AttachedActors)
		{
			Actors.Add(Actor);
			InitialRelativeTransforms.Add(Actor.RootComponent.RelativeTransform);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (int i = 0; i < Actors.Num(); i++)
		{
			FTransform Transform = InitialRelativeTransforms[i];
//			Transform.Rotation = Transform.Rotation * FQuat::MakeFromZX(WaveComponent.GetNormalAtLocation(InitialRelativeTransforms[i].Location), InitialRelativeTransforms[i].Rotation.ForwardVector);

//			Debug::DrawDebugLine(Actors[i].ActorLocation, Actors[i].ActorLocation + Transform.Rotation.UpVector * 300.0, FLinearColor::Blue, 10.0, 0.0);
			Transform.Location = Transform.Location + WaveComponent.GetOffsetAtLocation(InitialRelativeTransforms[i].Location);
			Actors[i].ActorTransform = Transform * ActorTransform;
		}
	}

	UFUNCTION(CallInEditor)
	void BuildGrid()
	{
		ClearGrid();

		for (int x = 0; x < Size.X; x++)		
			for (int y = 0; y < Size.Y; y++)
				for (int z = 0; z < Size.Z; z++)
				{
					FTransform Transform;
					FVector Location;
					FRotator Rotation = ActorRotation;
					Location.X = x * Spacing;
					Location.Y = y * Spacing;
					Location.Z = z * Spacing;

					Transform.Location = Location;

					auto Actor = SpawnActor(ActorClass, Transform.Location, Transform.Rotator(), bDeferredSpawn = false);
					Actor.AttachToActor(this);
					FHitResult HitResult;
					Actor.SetActorRelativeLocation(Transform.Location, false, HitResult, true);
				//	FinishSpawningActor(Actor);
//					Actors.Add(Actor);
//					InitialRelativeTransforms.Add(Transform);
				}
	}

	void ClearGrid()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for (auto Actor : AttachedActors)
			Actor.DestroyActor();

/*
		for (auto Actor : Actors)
			Actor.DestroyActor();
*/

		Actors.Empty();
		InitialRelativeTransforms.Empty();
	}
}