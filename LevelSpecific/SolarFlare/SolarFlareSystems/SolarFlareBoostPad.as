class ASolarFlareBoostPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoostOverlap;

	UPROPERTY(EditAnywhere)
	float BoostPower = 3000.0;

	UPROPERTY(EditAnywhere)
	FVector AdditionalBoost;

	TArray<AHazePlayerCharacter> Players;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");

		BoostOverlap.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		BoostOverlap.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		for (AHazePlayerCharacter CurrentPlayer : Players)
		{
			FVector Boost = BoostOverlap.UpVector * BoostPower;
			Boost += ActorForwardVector * AdditionalBoost.X;
			Boost += ActorRightVector * AdditionalBoost.Y;
			Boost += ActorUpVector * AdditionalBoost.Z;
			CurrentPlayer.AddMovementImpulse(Boost, n"SolarFlareBoostPad");
		}
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			Players.AddUnique(Player);
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			Players.Remove(Player);
	}
}