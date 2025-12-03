class AStormSiegeSinkingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapComp;

	TPerPlayer<bool> Players;

	FVector EndLocation;
	FVector StartLocation;

	UPROPERTY(EditAnywhere)
	float SinkSpeed = 200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		OverlapComp.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");

		StartLocation = MeshRoot.RelativeLocation;
		EndLocation = StartLocation - FVector::UpVector * 1200.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Players[0] || Players[1])
		{
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, EndLocation, DeltaSeconds, SinkSpeed);
		}
		else
		{
			MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, StartLocation, DeltaSeconds, SinkSpeed);
		}
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		Players[Player] = true;
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		Players[Player] = false;
	}
};