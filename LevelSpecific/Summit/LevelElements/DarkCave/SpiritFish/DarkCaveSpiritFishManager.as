class ADarkCaveSpiritFishManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(5));
#endif

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float MinSpawnRate = 1.5;

	UPROPERTY(EditAnywhere)
	float MaxSpawnRate = 3.5;

	UPROPERTY(EditAnywhere)
	int InitialFishSpawnAmount = 5;

	float SpawnTime;

	UPROPERTY()
	TSubclassOf<ADarkCaveSpiritFish> SpiritFishClass;

	UHazeActorNetworkedSpawnPoolComponent SpawnPoolComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnPoolComp = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(SpiritFishClass, this);
		if (!HasControl())
			return;

		float SplineLength = SplineActor.Spline.SplineLength;
		float MaxDistance = (SplineLength * 0.65) + Math::RandRange(-SplineLength*0.15, SplineLength*0.15);
		float MinDistance = (SplineLength * 0.05);
		if (InitialFishSpawnAmount > 0)
		{
			float OffsetPerFish = MaxDistance / InitialFishSpawnAmount;
			float CurrentOffset = MinDistance;
			for (int i = 0; i < InitialFishSpawnAmount; i++)
			{
				SpawnFish(CurrentOffset);
				CurrentOffset += OffsetPerFish;
			}
		}
		SpawnTime = Time::GameTimeSeconds + Math::RandRange(MinSpawnRate, MaxSpawnRate);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HasControl())
			return;

		if (Time::GameTimeSeconds > SpawnTime)
		{
			SpawnFish(SplineDistance = 0);
			SpawnTime = Time::GameTimeSeconds + Math::RandRange(MinSpawnRate, MaxSpawnRate);
		}
	}

	void SpawnFish(float SplineDistance)
	{
		int RandSeed = Math::Rand();
		FRandomStream Stream = FRandomStream(RandSeed);
		FSplinePosition SplinePos = SplineActor.Spline.GetSplinePositionAtSplineDistance(SplineDistance);
		FHazeActorSpawnParameters SpawnParams;
		SpawnParams.Location = SplinePos.WorldLocation;
		SpawnParams.Rotation = SplinePos.WorldRotation.Rotator();
		ADarkCaveSpiritFish Fish = Cast<ADarkCaveSpiritFish>(SpawnPoolComp.SpawnControl(SpawnParams));
		Fish.NetSpawnInitialize(Stream, this, SplineActor.Spline, SplineDistance);
	}
};