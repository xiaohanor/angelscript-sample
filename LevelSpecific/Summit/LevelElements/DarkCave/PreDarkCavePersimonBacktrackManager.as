class APreDarkCavePersimonBacktrackManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	FVector StartLocation;
	FVector EndLocation;

	UPROPERTY(EditAnywhere)
	FVector Offset = FVector(0.0, 0.0, -1000.0);

	FHazeAcceleratedVector AccelVec;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	void SetOffset()
	{
		EndLocation = ActorLocation;
		StartLocation = ActorLocation + Offset;
		ActorLocation = StartLocation;
		AccelVec.SnapTo(ActorLocation);
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccelVec.AccelerateTo(EndLocation, 2.5, DeltaSeconds); 
		ActorLocation = AccelVec.Value;
	}
};