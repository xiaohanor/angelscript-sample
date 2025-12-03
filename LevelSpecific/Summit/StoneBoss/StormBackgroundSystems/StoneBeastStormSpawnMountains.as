struct FStormMountainActorData
{
	AStoneBeastStormMountain MountainActor;
	FVector RelativeLocation;

	TArray<UPrimitiveComponent> ComponentsToMove;
	TArray<FTransform> ComponentRelativeTransforms;
}

class AStoneBeastStormSpawnMountains : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent)
	// UDisableComponent DisableComp;
	// default DisableComp.bAutoDisable = true;
	// default DisableComp.AutoDisableRange = 40000;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(70.0));
#endif

	// UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	// float StartForwardOffset = -80000.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float MaxRightOffset = 40000.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float MaxHeightOffset = 5000.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float DefaultHeightOffset = 15000.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float LifeTime = 10.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float MaxDistanceTravelled = 300000.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float MoveSpeed = 60000.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float MinSpawnRate = 0.4;

	UPROPERTY(EditAnywhere, Category = "Setup|Spawn Settings")
	float MaxSpawnRate = 0.2;

	UPROPERTY(EditAnywhere, Category = "Setup|Bobbing")
	float ZBobAmount = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Bobbing")
	float ZBobSpeed = 1.1;

	UPROPERTY(EditAnywhere, Category = "Setup|Pitching")
	float PitchAmount = 6.0;

	UPROPERTY(EditAnywhere, Category = "Setup|Pitching")
	float PitchSpeed = 1.2;

	float SpawnTime;

	UPROPERTY()
	TArray<TSubclassOf<AStoneBeastStormMountain>> MountainClasses;

	TArray<FStormMountainActorData> MovingMeshActors;

	FVector MountainMoveDirection;

	FVector StartPosition;
	FRotator StartRot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			auto Mountain = Cast<AStoneBeastStormMountain>(Actor);
			if (Mountain != nullptr)
			{
				FStormMountainActorData ActorData;
				ActorData.MountainActor = Mountain;
				ActorData.RelativeLocation = ActorTransform.InverseTransformPosition(Mountain.ActorLocation);

				Mountain.SetActorEnableCollision(false);

				FTransform MountainTransform = Mountain.ActorTransform;

				Mountain.GetComponentsByClass(ActorData.ComponentsToMove);
				for (auto Comp : ActorData.ComponentsToMove)
				{
					FTransform Transform = Comp.GetWorldTransform();
					ActorData.ComponentRelativeTransforms.Add(FTransform::GetRelative(MountainTransform, Transform));
					Comp.SetAbsoluteAndUpdateTransform(true, true, true, Transform);
				}

				Mountain.Root.SetAbsolute(true, true, true);
				MovingMeshActors.Add(ActorData);
			}
		}

		MountainMoveDirection = FVector::ForwardVector;
		StartPosition = ActorRelativeLocation;
		StartRot = ActorRelativeRotation;
		Root.SetAbsolute(true, true, true);

		//Start Deactivated
		DeactivateMountainSpawn();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for (int i = MovingMeshActors.Num() - 1; i >= 0; i--)
		{
			MovingMeshActors[i].MountainActor.DestroyActor();
			MovingMeshActors.RemoveAt(i);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (MovingMeshActors.Num() == 0)
			return;

		FTransform ParentTransform;
		if (Root.AttachParent != nullptr)
			ParentTransform = Root.AttachParent.WorldTransform;

		FVector RootLocation = StartPosition + FVector::UpVector * (Math::Sin(Time::GameTimeSeconds * ZBobSpeed) * ZBobAmount);
		FRotator RootRotation = StartRot + FRotator(Math::Sin(Time::GameTimeSeconds * PitchSpeed) * PitchAmount, 0, 0);

		FTransform SpawnerTransform = FTransform::ApplyRelative(
			ParentTransform,
			FTransform(RootRotation, RootLocation));

		FVector SpawnerLocation = SpawnerTransform.Location;
		FVector SpawnerForwardVector = SpawnerTransform.Rotation.ForwardVector;

		for (FStormMountainActorData& Data : MovingMeshActors)
		{
			Data.RelativeLocation += MountainMoveDirection * MoveSpeed * DeltaSeconds;

			float DistanceAway = Math::Abs(Data.RelativeLocation.X);
			if (DistanceAway > MaxDistanceTravelled)
			{
				Data.RelativeLocation = GetNewRandomLocation(Data.RelativeLocation.Z);
			}

			FTransform MountainTransform = FTransform::ApplyRelative(
				SpawnerTransform, FTransform(Data.RelativeLocation)
			);
			for (int i = 0, Count = Data.ComponentsToMove.Num(); i < Count; ++i)
			{
				FTransform CompTransform = FTransform::ApplyRelative(
					MountainTransform, Data.ComponentRelativeTransforms[i]
				);

				SceneComponent::RapidChangeComponentLocationAndRotation(
					Data.ComponentsToMove[i],
					CompTransform.Location,
					CompTransform.Rotation,
				);
			}
		}
	}

	FVector GetNewRandomLocation(float Height)
	{
		float RandomOffset = Math::RandRange(-1, 1);
		RandomOffset *= MaxRightOffset;
		return FVector(0, RandomOffset, Height);
	}

	UFUNCTION()
	void SetPartTwoSlideNewDirection()
	{
		MountainMoveDirection += FVector(0, 0, 0.25);
		MountainMoveDirection.Normalize();
	}

	UFUNCTION()
	void ClearChangedMoveDirection()
	{
		MountainMoveDirection = FVector::ForwardVector;
	}

	UFUNCTION()
	void ActivateMountainSpawn()
	{
		for (int i = MovingMeshActors.Num() - 1; i >= 0; i--)
			MovingMeshActors[i].MountainActor.SetActorHiddenInGame(false);

		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateMountainSpawn()
	{
		for (int i = MovingMeshActors.Num() - 1; i >= 0; i--)
			MovingMeshActors[i].MountainActor.SetActorHiddenInGame(true);

		SetActorTickEnabled(false);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector Point1 = ActorLocation + ActorRightVector * MaxRightOffset;
		FVector Point2 = ActorLocation - ActorRightVector * MaxRightOffset;
		Debug::DrawDebugLine(Point1, Point2, FLinearColor::Green, 250, bDrawInForeground = true);

		FVector Point3 = ActorLocation + (ActorForwardVector * MaxDistanceTravelled) + (ActorRightVector * MaxRightOffset);
		FVector Point4 = ActorLocation + (ActorForwardVector * MaxDistanceTravelled) - (ActorRightVector * MaxRightOffset);
		Debug::DrawDebugLine(Point1, Point3, FLinearColor::Green, 250, bDrawInForeground = true);
		Debug::DrawDebugLine(Point2, Point4, FLinearColor::Green, 250, bDrawInForeground = true);
		Debug::DrawDebugLine(Point3, Point4, FLinearColor::Green, 250, bDrawInForeground = true);
	}
#endif

};