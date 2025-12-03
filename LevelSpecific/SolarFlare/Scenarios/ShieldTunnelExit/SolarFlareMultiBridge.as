class ASolarFlareMultiBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(EditAnywhere)
	FVector TargetOffset = FVector(0.0, 0.0, 1500.0);

	private FVector StartLoc;
	private float InterpSpeed = 1500.0;

	private bool bBridgeActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActorLocation -= TargetOffset;
		StartLoc = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bBridgeActive)
			ActorLocation = Math::VInterpConstantTo(ActorLocation, StartLoc + TargetOffset, DeltaSeconds, InterpSpeed);
		else
			ActorLocation = Math::VInterpConstantTo(ActorLocation, StartLoc, DeltaSeconds, InterpSpeed);
	}

	void ActivateMultiBridge()
	{
		bBridgeActive = true;
	}

	void DeactivateMultiBridge()
	{
		bBridgeActive = false;
	}
}