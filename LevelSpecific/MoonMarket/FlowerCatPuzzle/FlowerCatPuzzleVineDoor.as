class AFlowerCatPuzzleVineDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	float StartingHeight;

	UPROPERTY(EditAnywhere)
	const float TargetHeightWhenOpened;

	UPROPERTY(EditAnywhere)
	const float MoveDuration = 5;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve SpeedCurve;

	float ActiveTime = 0;

	bool bIsUnlocked = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<AFlowerCatPuzzle>().Single.OnFlowerCatPuzzleCompleted.AddUFunction(this, n"OpenDoor");
		StartingHeight = ActorLocation.Z;
	}

	UFUNCTION()
	private void OpenDoor()
	{
		bIsUnlocked = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(ActiveTime >= MoveDuration)
			return;

		if(bIsUnlocked)
		{
			float Alpha = SpeedCurve.GetFloatValue(ActiveTime / MoveDuration);
			float NewHeight = Math::Lerp(StartingHeight, TargetHeightWhenOpened, Alpha);
			SetActorLocation(FVector(ActorLocation.X, ActorLocation.Y, NewHeight));
			ActiveTime += DeltaSeconds;
		}
	}
};