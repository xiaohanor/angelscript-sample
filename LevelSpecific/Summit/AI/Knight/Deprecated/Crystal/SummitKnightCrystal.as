class ASummitKnightCrystal : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightCrystalPhase1Capability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightCrystalPhase2Capability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitKnightCrystalPhase3Capability");

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent MainCrystal;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent SubCrystal1;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent SubCrystal2;

	UPROPERTY(DefaultComponent, BlueprintReadOnly)
	UStaticMeshComponent SubCrystal3;

	UPROPERTY(EditAnywhere)
	AAISummitKnight Knight1;

	UPROPERTY(EditAnywhere)
	AAISummitKnight Knight2;

	UPROPERTY(EditAnywhere)
	AAISummitKnightBro Knight3;

	UPROPERTY(EditAnywhere)
	ASummitKnightHorse HorseKnight;

	float BobSeconds;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorWorldRotation(FRotator(0, 40 * DeltaSeconds, 0));
		BobSeconds += DeltaSeconds;
		float Offset = Math::Sin(BobSeconds);
		FVector BobLocation = StartLocation + FVector(0, 0, 200 * Offset);
		SetActorLocation(BobLocation);		
	}
}