class ASummitWaterFallWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovementComp;

	FRotator CurrentRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void SetWheelRotation(FRotator RotationSpeed)
	{
		RotatingMovementComp.RotationRate = RotationSpeed;

	}

	UFUNCTION()
	void StopRotationOnWheel()
	{
		CurrentRotation = GetActorRotation();
		RotatingMovementComp.RotationRate = FRotator(0,0,0);
		SetActorRotation(CurrentRotation);
		// SetActorRelativeRotation(CurrentRotation);
	}
};