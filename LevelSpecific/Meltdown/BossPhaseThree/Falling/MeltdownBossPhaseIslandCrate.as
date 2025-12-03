class AMeltdownBossPhaseIslandCrate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Crate;

	UPROPERTY(EditAnywhere)
	APlayerTrigger ShipTrigger;

	UPROPERTY(EditAnywhere)
	float Speed = 1500;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);

		ShipTrigger.OnActorBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	private void OnOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		SetActorTickEnabled(true);

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalOffset(FVector::UpVector * Speed * DeltaSeconds);
		Crate.AddLocalRotation(FRotator(2,2,2));
	}
};