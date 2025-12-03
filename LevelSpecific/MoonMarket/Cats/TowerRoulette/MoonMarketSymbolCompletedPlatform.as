class AMoonMarketSymbolCompletedPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	FVector StartLocation;
	FVector EndLocation;
	float ZOffset = 3000.0;
	float MoveSpeed = 3000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EndLocation = ActorLocation;
		StartLocation = ActorLocation - FVector::UpVector * ZOffset;
		ActorLocation = StartLocation;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, EndLocation, DeltaSeconds, MoveSpeed);
	}

	void ActivateFinalPlatform()
	{
		SetActorTickEnabled(true);
	}
};