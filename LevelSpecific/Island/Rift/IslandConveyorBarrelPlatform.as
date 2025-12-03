UCLASS(Abstract)
class AIslandConveyorBarrelPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeRotateComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent BarrelPoint;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsWeightComponent WeightComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AIslandConveyorBarrel> Barrel;

	UPROPERTY()
	TArray<AIslandConveyorBarrel> SpawnedBarrels;

	float BarrelOffset = 110;
	int BarrelMaxAmount = 3;
	int BarrelMinAmount = 1;
	int BarrelAmount;

	FHazeAcceleratedVector AcceleratedSpeed;
	FVector PreviousLocation;

	TArray<FVector> PossibleSpawnLocations;
	default PossibleSpawnLocations.Add(FVector(BarrelOffset, BarrelOffset, 0.0));
	default PossibleSpawnLocations.Add(FVector(-BarrelOffset, BarrelOffset, 0.0));
	default PossibleSpawnLocations.Add(FVector(BarrelOffset, -BarrelOffset, 0.0));
	default PossibleSpawnLocations.Add(FVector(-BarrelOffset, -BarrelOffset, 0.0));

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnBarrels();
		ResetAndEnableBarrels(true);
		PreviousLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector MovementDelta = ActorLocation - PreviousLocation;
		ConeRotateComp.ApplyForce(ConeRotateComp.WorldLocation, MovementDelta * 3);
		PreviousLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		PreviousLocation = ActorLocation;
		ResetAndEnableBarrels();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		DisableBarrels();
	}

	void SpawnBarrels()
	{
		for(int i = 0; i < 4; ++i)
		{
			auto SpawnedBarrel = SpawnActor(Barrel, BarrelPoint.WorldLocation, BarrelPoint.WorldRotation, bDeferredSpawn = true);
			SpawnedBarrel.MakeNetworked(this, n"SpawnedBarrel", i);
			FinishSpawningActor(SpawnedBarrel);
			BarrelSetup(SpawnedBarrel, i);
		}
	}

	UFUNCTION()
	void BarrelSetup(AIslandConveyorBarrel SpawnedBarrel, int Index)
	{
		SpawnedBarrel.OnExploded.AddUFunction(this, n"OnBarrelExploded");
		SpawnedBarrel.bDisableHook = true;
		SpawnedBarrel.BP_ResetBarrel();
		SpawnedBarrels.AddUnique(SpawnedBarrel);

		SpawnedBarrel.AttachToComponent(RotateRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		
		SpawnedBarrel.AddActorLocalOffset(PossibleSpawnLocations[Index]);
	}
	
	UFUNCTION()
	private void OnBarrelExploded(AIslandConveyorBarrel ExplodedBarrel)
	{
		ExplodedBarrel.OnExploded.UnbindObject(this);
	}

	void DisableBarrels()
	{
		for(auto SpawnedBarrel : SpawnedBarrels)
		{
			SpawnedBarrel.AddActorDisable(SpawnedBarrel);
		}
	}

	void ResetAndEnableBarrels(bool bSetRotation = false)
	{
		if(!HasControl())
			return;

		int BitMask = 0;
		BarrelAmount = CalculateBarrelAmount();

		// Pick a random configuration of barrels that should be enabled
		if(BarrelAmount < 4)
		{
			TArray<int> Indices;
			for(int i = 0; i < 4; i++)
			{
				Indices.Add(i);
			}
			
			for(int i = 0; i < BarrelAmount; i++)
			{
				int Rand = Math::RandRange(0, Indices.Num() - 1);
				int Index = Indices[Rand];
				Indices.RemoveAt(Rand);
				BitMask |= 1 << Index;
			}
		}
		else
			BitMask = MAX_uint8;

		TArray<uint8> RandomYawRotations;
		if(bSetRotation)
		{
			for(int i = 0; i < 4; i++)
			{
				RandomYawRotations.Add(uint8(Math::RandRange(1, 3)));
			}
		}

		CrumbResetAndEnableBarrels(uint8(BitMask), RandomYawRotations);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbResetAndEnableBarrels(uint8 EnableBitMask, TArray<uint8> RandomYaw)
	{
		for(int i = 0; i < SpawnedBarrels.Num(); i++)
		{
			AIslandConveyorBarrel SpawnedBarrel = SpawnedBarrels[i];
			SpawnedBarrel.BP_ResetBarrel();

			if(RandomYaw.Num() > i)
				SpawnedBarrel.AddActorLocalRotation(FRotator(0, 90 * RandomYaw[i], 0));

			if((1 << i) & EnableBitMask == 0)
				SpawnedBarrel.AddActorDisable(SpawnedBarrel);
		}
	}

	UFUNCTION(BlueprintCallable)
	void BP_ResetBarrelPlatform()
	{
		ResetAndEnableBarrels();
	}

	int CalculateBarrelAmount()
	{
		return Math::RandRange(Math::Clamp(BarrelMinAmount, 0, 3), Math::Clamp(BarrelMaxAmount, 1, 4));
	}
}