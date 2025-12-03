class AGraveyardTombInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(EditInstanceOnly)
	ADoubleInteractionActor DoubleInteract;

	UPROPERTY(EditInstanceOnly)
	TArray<AGraveyardTombRetractable> Tombstones;

	float ZOffset = -400;
	FVector TargetLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");
		TargetLoc = ActorLocation + (FVector::UpVector * ZOffset);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation = Math::VInterpConstantTo(ActorLocation, TargetLoc, DeltaSeconds, Math::Abs(ZOffset) / 2.0);
	}

	UFUNCTION()
	private void OnDoubleInteractionCompleted()
	{
		SetActorTickEnabled(true);
		DoubleInteract.AddActorDisable(this);
		Timer::SetTimer(this, n"DelayedTombMoves", 0.4);
	}

	UFUNCTION()
	void DelayedTombMoves()
	{
		for (AGraveyardTombRetractable Tomb : Tombstones)
		{
			Tomb.ActivateTombStone();
		}
	}
};