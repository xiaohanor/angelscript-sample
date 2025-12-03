class AStormFallObjectSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));	
#endif

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UBoxComponent SpawnArea;
	default SpawnArea.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default SpawnArea.BoxExtent = FVector(1500.0, 1500.0, 250.0);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;
	default ListComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditAnywhere, Category = "Setup")
	TSubclassOf<AStormFallObject> RiseObjClass;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinSpawnRate = 4.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxSpawnRate = 8.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float ZStartOffsetRange = 5000.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	int StartingObjectCount = 4;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float RotationOffsetValue = 80.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartEnabled = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bDrawDisableRange = true;
	default DisableComp.AutoDisableRange = 30000;

	float SpawnTime;

	int PreSpawnAmount = 30;

	float OverrideLifeTime = 20.0;
	bool bUseOverrideLifeTime = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		/** Note for John: I removed spawning in beginplay in order to let the disablecomp have a chance to kick in first, to prevent spawning objects while miles away. */
		SetActorTickEnabled(bStartEnabled);
		if (bStartEnabled)
		{
			RunPreSpawn();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnTime = Time::GameTimeSeconds + Math::RandRange(MinSpawnRate, MaxSpawnRate);
			SpawnObject();
		}
	}

	AStormFallObject SpawnObject(float PreSpawnUpOffset = 0.0, bool bRandRange = false)
	{
		FVector Extents = SpawnArea.BoxExtent;
		float XOffset = Math::RandRange(-Extents.X, Extents.X);
		float YOffset = Math::RandRange(-Extents.Y, Extents.Y);
		float ZOffset = Math::RandRange(-Extents.Z, Extents.Z);
		FVector Offset = FVector(XOffset, YOffset, ZOffset);

		float PitchOffset = Math::RandRange(-RotationOffsetValue, RotationOffsetValue);
		float YawOffset = Math::RandRange(-RotationOffsetValue, RotationOffsetValue);
		float RollOffset = Math::RandRange(-RotationOffsetValue, RotationOffsetValue);
		FRotator OffsetRotation = FRotator(PitchOffset, YawOffset, RollOffset);

		auto RisingObject = SpawnActor(RiseObjClass, ActorLocation + Offset + (FVector::UpVector * PreSpawnUpOffset), ActorRotation + OffsetRotation, NAME_None, true);

		if (bUseOverrideLifeTime)
			RisingObject.LifeDuration = OverrideLifeTime;
		
		if (bRandRange)
			RisingObject.RandRangeInitializeObject();
		else
			RisingObject.InitializeObject();

		FinishSpawningActor(RisingObject);
		return RisingObject;
	}

	UFUNCTION()
	void ActivateSpawner()
	{
		RunPreSpawn();
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void DeactivateSpawner()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	void SetOverrideLifeTime(bool bOverrideStonebeast = true, float NewLifeTime = 20.0)
	{
		bUseOverrideLifeTime = bOverrideStonebeast;
		OverrideLifeTime = NewLifeTime;
	}

	void RunPreSpawn()
	{
		float UpAmount = 3500.0;
		float CurrentUpoffset = 0.0;

		for (int i = 0; i < PreSpawnAmount; i++)
		{
			CurrentUpoffset += UpAmount; 
			SpawnObject(CurrentUpoffset, true);
		}
	}
}