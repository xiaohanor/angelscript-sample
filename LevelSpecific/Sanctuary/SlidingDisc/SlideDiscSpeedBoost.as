class ASlideDiscSpeedBoost : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	EInstigatePriority Priority = EInstigatePriority::Override;
		
	UPROPERTY(EditAnywhere)
	ASlidingDisc SlidingDisc;

	UPROPERTY(EditAnywhere)
	FVector SpeedBoost = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeave");
		
	}

	UFUNCTION()
	private void HandlePlayerLeave(AHazePlayerCharacter Player)
	{
		SlidingDisc.BoostForce = FVector::ZeroVector;
	}

	UFUNCTION()
	private void HandlePlayerEnter(AHazePlayerCharacter Player)
	{
		SlidingDisc.BoostForce = ActorForwardVector * 2000.0;
		//SlidingDisc.AddMovementImpulse(SlidingDisc.GetActorForwardVector() * 5000.0);
	}
};

