class ASkylineBossObeliskDrop : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDecalComponent Decal;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(EditAnywhere)
	float FallHeight = 50000.0;

	UPROPERTY(EditAnywhere)
	float FallingSpeed = 20000.0;

	UPROPERTY(EditAnywhere)
	float DetonationTime = 5.0;
	float DetonationTimeStamp = 0.0;

	float CurrentHeight = 0.0;
	bool bIsFalling = false;
	bool bHasLanded = false;
	bool bDetonated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentHeight = FallHeight;
		Pivot.RelativeLocation = FVector::UpVector * CurrentHeight;
		Drop();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsFalling)
		{
			CurrentHeight -= FallingSpeed * DeltaSeconds;
			Pivot.RelativeLocation = FVector::UpVector * Math::Max(0.0, CurrentHeight);

			Decal.RelativeScale3D = FVector::OneVector * Math::Max(SMALL_NUMBER, (1.0 - (CurrentHeight / FallHeight)));

			if (CurrentHeight <= 0.0)
				Land();
		}

		if (bHasLanded)
		{
			if (!bDetonated && Time::GameTimeSeconds > DetonationTimeStamp)
				Detonate();
		}
	}

	void Drop()
	{
		bIsFalling = true;
	}

	void Land()
	{
		bIsFalling = false;
		bHasLanded = true;
		DetonationTimeStamp = Time::GameTimeSeconds + DetonationTime;
	}

	void Detonate()
	{
		bDetonated = true;
		DestroyActor();
	}
};