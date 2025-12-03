class AGraveyardTombRetractable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	float DelayTime = 0.0;

	float ForwardOffset = 500.0;

	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetLoc = ActorLocation;
		ActorLocation -= ActorForwardVector * ForwardOffset;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (DelayTime > 0.0)
		{
			DelayTime -= DeltaSeconds;
			return;
		}

		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLoc, DeltaSeconds, ForwardOffset / 2.5);
	}

	UFUNCTION()
	void ActivateTombStone()
	{
		SetActorTickEnabled(true);
	}
};