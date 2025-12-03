enum ECrystalMetalSplineSpawnType
{
	Metal,
	Crystal
}

class ACrystalMetalSplineSpawn : ASplineActor
{
#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(EditAnywhere)
	ECrystalMetalSplineSpawnType SpawnType;

	UPROPERTY(EditAnywhere)
	float SpawnRate = 0.25;
	float SpawnTime;

	UPROPERTY(EditAnywhere)
	float SpawnDistance = 2500.0;

	UPROPERTY()
	TSubclassOf<AVineMetalSpike> MetalClass;

	UPROPERTY()
	TSubclassOf<AVineGemSpike> CrystalClass;

	float CurrentDistance;
	bool bObjectsSpawned;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		SpawnTime -= DeltaSeconds;
		
		while (SpawnTime <= 0.0)
		{
			SpawnTime += SpawnRate;
			
			AVineMetalSpike Metal;
			AVineGemSpike Crystal;

			switch(SpawnType)
			{
				case ECrystalMetalSplineSpawnType::Crystal:
					Crystal = Cast<AVineGemSpike>(SpawnActor(CrystalClass, 
					Spline.GetWorldLocationAtSplineDistance(CurrentDistance), 
					Spline.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator()));
					break;
				case ECrystalMetalSplineSpawnType::Metal:
					Metal = Cast<AVineMetalSpike>(SpawnActor(MetalClass, 
					Spline.GetWorldLocationAtSplineDistance(CurrentDistance), 
					Spline.GetWorldRotationAtSplineDistance(CurrentDistance).Rotator()));
					break;
			}

			if (Crystal != nullptr)
				Crystal.ActivateSpike();
			if (Metal != nullptr)
				Metal.ActivateSpike();

			CurrentDistance += SpawnDistance;

			if (CurrentDistance >= Spline.SplineLength)
				CompleteSplineSpawn();
		}
	}

	UFUNCTION()
	void ActivateSplineSpawn()
	{
		if (bObjectsSpawned)
			return;

		SetActorTickEnabled(true);
		bObjectsSpawned = true;
	}

	void CompleteSplineSpawn()
	{
		SetActorTickEnabled(false);
	}
}